use std::sync::atomic::{AtomicBool, Ordering};

use tauri::{
    menu::{CheckMenuItem, Menu, MenuItem, PredefinedMenuItem},
    tray::TrayIconBuilder,
    Emitter, LogicalPosition, LogicalSize, Manager,
};
use tauri_plugin_autostart::MacosLauncher;
use tauri_plugin_global_shortcut::{
    Code, GlobalShortcutExt, Modifiers, Shortcut, ShortcutEvent, ShortcutState,
};

// ── Managed state ────────────────────────────────────────────────────────────

struct AuthState(AtomicBool);
struct RecordingMode(AtomicBool); // false = click-to-record, true = hold-to-record

// CheckMenuItem is a thin Arc-backed handle — Send + Sync without a Mutex.
struct HoldModeItem(CheckMenuItem<tauri::Wry>);

// ── Tauri commands ────────────────────────────────────────────────────────────

#[tauri::command]
fn set_authenticated(app: tauri::AppHandle, value: bool) {
    app.state::<AuthState>().0.store(value, Ordering::Relaxed);
}

#[tauri::command]
fn session_expired(app: tauri::AppHandle) {
    app.state::<AuthState>().0.store(false, Ordering::Relaxed);
    if let Some(win) = app.get_webview_window("login") {
        let _ = win.emit("do-logout", ());
        let _ = win.center();
        let _ = win.show();
        let _ = win.set_focus();
    }
    if let Some(win) = app.get_webview_window("main") {
        let _ = win.hide();
    }
}

// Called on app startup to sync the frontend's localStorage preference into
// Rust state, and again whenever the frontend acknowledges a mode change.
#[tauri::command]
fn set_recording_mode(app: tauri::AppHandle, hold: bool) {
    app.state::<RecordingMode>().0.store(hold, Ordering::Relaxed);
    let _ = app.state::<HoldModeItem>().0.set_checked(hold);
}

// ── macOS window level ────────────────────────────────────────────────────────

/// Set the collection-behaviour flags that let the window appear on every
/// Space and over full-screen apps.  The *level* is handled separately via
/// Tauri's set_always_on_top() (= NSFloatingWindowLevel = 3); we deliberately
/// do NOT call setLevel: here because level-25 (NSStatusWindowLevel) places
/// the window in the menu-bar tier, which macOS clips outside the normal
/// screen area — that is what was causing the window not to appear.
#[cfg(target_os = "macos")]
unsafe fn set_collection_behavior(win: &tauri::WebviewWindow) {
    use objc2::msg_send;
    use objc2::runtime::AnyObject;

    let raw = match win.ns_window() {
        Ok(ptr) => ptr,
        Err(_) => return,
    };
    let ns_win: *mut AnyObject = raw as *mut AnyObject;

    // OR in two flags:
    //   NSWindowCollectionBehaviorCanJoinAllSpaces    = 1   (bit 0)
    //   NSWindowCollectionBehaviorFullScreenAuxiliary = 256 (bit 8)
    let behavior: u64 = msg_send![ns_win, collectionBehavior];
    let _: () = msg_send![ns_win, setCollectionBehavior: behavior | 1u64 | 256u64];
}

// ── Window helpers ────────────────────────────────────────────────────────────

/// Force the app to the front so our floating window beats Safari / Chrome.
/// macOS won't raise another app's window unless it is the active application,
/// so we activate first, then show.
#[cfg(target_os = "macos")]
unsafe fn activate_app() {
    use objc2::msg_send;
    use objc2::runtime::{AnyClass, AnyObject};
    if let Some(cls) = AnyClass::get(c"NSApplication") {
        let app: *mut AnyObject = msg_send![cls, sharedApplication];
        if !app.is_null() {
            let _: () = msg_send![app, activateIgnoringOtherApps: true];
        }
    }
}

/// Show the capture window at the screen's bottom-right corner in hold mode.
fn show_hold_window(app: &tauri::AppHandle) {
    let Some(win) = app.get_webview_window("main") else { return };
    let _ = win.set_size(LogicalSize::new(300u32, 110u32));

    let monitor = win
        .current_monitor()
        .ok()
        .flatten()
        .or_else(|| win.primary_monitor().ok().flatten());

    if let Some(monitor) = monitor {
        let scale = monitor.scale_factor();
        let mon = monitor.size().to_logical::<i32>(scale);
        let x = mon.width  - 300 - 20;
        let y = mon.height - 110 - 80;
        let _ = win.set_position(LogicalPosition::new(x, y));
    } else {
        let _ = win.center();
    }

    #[cfg(target_os = "macos")]
    unsafe { activate_app(); }

    let _ = win.show();
    let _ = win.set_always_on_top(true);
    let _ = win.set_focus();
    // "shortcut-pressed" tells the frontend to set visible=true and start recording.
    let _ = win.emit("shortcut-pressed", ());
}

/// Show the capture window centred on screen in click mode (320 × 260).
fn show_click_window(app: &tauri::AppHandle) {
    let Some(win) = app.get_webview_window("main") else { return };
    let _ = win.set_size(LogicalSize::new(320u32, 260u32));

    #[cfg(target_os = "macos")]
    unsafe { activate_app(); }

    let _ = win.show();
    let _ = win.center();
    let _ = win.set_always_on_top(true);
    let _ = win.set_focus();
    // Emit a reliable "window is now shown" signal so the frontend can
    // set visible=true without depending on tauri://focus, which macOS
    // suppresses when another app (Safari, etc.) owns focus.
    let _ = win.emit("window-shown", ());
}

// ── App entry point ───────────────────────────────────────────────────────────

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(AuthState(AtomicBool::new(false)))
        .manage(RecordingMode(AtomicBool::new(false)))
        // HoldModeItem is registered after the tray is built in setup().
        .invoke_handler(tauri::generate_handler![
            set_authenticated,
            session_expired,
            set_recording_mode,
        ])
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            Some(vec![]),
        ))
        .plugin(
            tauri_plugin_global_shortcut::Builder::new()
                .with_handler(
                    |app: &tauri::AppHandle, _shortcut: &Shortcut, event: ShortcutEvent| {
                        let is_auth = app.state::<AuthState>().0.load(Ordering::Relaxed);
                        if !is_auth {
                            // Not logged in — surface the login window.
                            if let Some(win) = app.get_webview_window("login") {
                                if !win.is_visible().unwrap_or(false) {
                                    let _ = win.center();
                                    let _ = win.show();
                                }
                                let _ = win.set_focus();
                            }
                            return;
                        }

                        let is_hold = app.state::<RecordingMode>().0.load(Ordering::Relaxed);

                        match event.state() {
                            ShortcutState::Pressed => {
                                if is_hold {
                                    // Hold mode — show bottom-right and begin recording.
                                    show_hold_window(app);
                                } else {
                                    // Click mode — toggle the centred window.
                                    if let Some(win) = app.get_webview_window("main") {
                                        if win.is_visible().unwrap_or(false) {
                                            let _ = win.hide();
                                        } else {
                                            show_click_window(app);
                                        }
                                    }
                                }
                            }
                            ShortcutState::Released => {
                                // Only meaningful in hold mode — tell the frontend to
                                // stop recording and send.
                                if is_hold {
                                    if let Some(win) = app.get_webview_window("main") {
                                        let _ = win.emit("shortcut-released", ());
                                    }
                                }
                            }
                        }
                    },
                )
                .build(),
        )
        .setup(|app| {
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            // Set the all-spaces / full-screen collection behaviour once at
            // startup.  The floating level is re-asserted by set_always_on_top
            // inside show_click_window / show_hold_window every time the
            // window is displayed.
            #[cfg(target_os = "macos")]
            if let Some(win) = app.get_webview_window("main") {
                unsafe { set_collection_behavior(&win); }
            }

            use tauri_plugin_autostart::ManagerExt;
            let is_autostart = app.autolaunch().is_enabled().unwrap_or(false);

            // ── Tray menu ─────────────────────────────────────────────────
            let autostart_item = CheckMenuItem::with_id(
                app, "autostart", "Launch at Login",
                true, is_autostart, None::<&str>,
            )?;
            let hold_item = CheckMenuItem::with_id(
                app, "hold-mode", "Hold to Record",
                true, false, None::<&str>,
            )?;
            let sep1 = PredefinedMenuItem::separator(app)?;
            let sep2 = PredefinedMenuItem::separator(app)?;
            let sep3 = PredefinedMenuItem::separator(app)?;
            let logout_item = MenuItem::with_id(app, "logout", "Log Out",   true, None::<&str>)?;
            let quit_item   = MenuItem::with_id(app, "quit",   "Quit TaskSnap", true, None::<&str>)?;

            let menu = Menu::with_items(app, &[
                &hold_item,
                &sep1,
                &autostart_item,
                &sep2,
                &logout_item,
                &sep3,
                &quit_item,
            ])?;

            // Register HoldModeItem into managed state so set_recording_mode
            // can update the checkmark from the command.
            app.manage(HoldModeItem(hold_item.clone()));

            let autostart_item_clone = autostart_item.clone();
            let hold_item_clone      = hold_item.clone();

            TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .tooltip("TaskSnap — Ctrl+Space to capture")
                .show_menu_on_left_click(false)
                .on_menu_event(move |app, event| match event.id.as_ref() {
                    "hold-mode" => {
                        let was_hold = app.state::<RecordingMode>().0.load(Ordering::Relaxed);
                        let new_hold = !was_hold;
                        app.state::<RecordingMode>().0.store(new_hold, Ordering::Relaxed);
                        let _ = hold_item_clone.set_checked(new_hold);
                        // Tell the frontend so it can persist to localStorage.
                        for label in ["main", "login"] {
                            if let Some(win) = app.get_webview_window(label) {
                                let _ = win.emit("recording-mode-changed", new_hold);
                            }
                        }
                        // If capture window is open, close it cleanly.
                        if let Some(win) = app.get_webview_window("main") {
                            let _ = win.hide();
                        }
                    }
                    "autostart" => {
                        use tauri_plugin_autostart::ManagerExt;
                        let autolaunch = app.autolaunch();
                        if autolaunch.is_enabled().unwrap_or(false) {
                            let _ = autolaunch.disable();
                            let _ = autostart_item_clone.set_checked(false);
                        } else {
                            let _ = autolaunch.enable();
                            let _ = autostart_item_clone.set_checked(true);
                        }
                    }
                    "logout" => {
                        app.state::<AuthState>().0.store(false, Ordering::Relaxed);
                        if let Some(win) = app.get_webview_window("login") {
                            let _ = win.emit("do-logout", ());
                            let _ = win.center();
                            let _ = win.show();
                            let _ = win.set_focus();
                        }
                        if let Some(win) = app.get_webview_window("main") {
                            let _ = win.hide();
                        }
                    }
                    "quit" => app.exit(0),
                    _ => {}
                })
                .build(app)?;

            let shortcut = Shortcut::new(Some(Modifiers::CONTROL), Code::Space);
            app.global_shortcut().register(shortcut)?;

            Ok(())
        })
        .on_window_event(|window, event| {
            if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                let _ = window.hide();
                api.prevent_close();
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
