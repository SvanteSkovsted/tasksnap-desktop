# TaskSnap Desktop

A lightweight Tauri v2 desktop app (Mac + Windows) that sits in your system tray and lets you capture voice tasks with a global keyboard shortcut.

**How it works:**
1. Press **Ctrl+Space** anywhere — a small floating window appears
2. Hold the microphone button and speak your task
3. Release — audio is encoded as base64 and POSTed to your Supabase Edge Function
4. The window closes automatically; all AI logic runs server-side

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | ≥ 18 | https://nodejs.org |
| Rust | stable | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Xcode CLT (macOS) | latest | `xcode-select --install` |
| WebView2 (Windows) | latest | Usually pre-installed on Win 10/11 |

---

## Quick Setup

```bash
# 1. Clone / enter the project
cd tasksnap-desktop

# 2. Install JS dependencies
npm install

# 3. Generate proper app icons from a 1024×1024 source image
#    (placeholder icons are included — replace them before distributing)
npm run tauri icon src-tauri/icons/icon.png

# 4. Copy and fill in your Supabase endpoint
cp .env.example .env
# Edit .env and set VITE_SUPABASE_ENDPOINT=https://...

# 5. Start the dev server
npm run tauri dev
```

---

## Configuration

Edit `.env`:

```
VITE_SUPABASE_ENDPOINT=https://<project>.supabase.co/functions/v1/<function-name>
```

The app POSTs JSON:
```json
{
  "audio": "<base64-encoded webm>",
  "mimeType": "audio/webm"
}
```

Your Edge Function receives this and handles all AI / todo / calendar logic.

---

## Building a distributable

```bash
# macOS (produces .dmg + .app)
npm run tauri build

# Windows (produces .msi + .exe) — run on a Windows machine or CI
npm run tauri build
```

Artifacts land in `src-tauri/target/release/bundle/`.

---

## Usage

| Action | Effect |
|--------|--------|
| **Ctrl+Space** | Show / hide the capture window |
| Hold mic button | Record audio |
| Release mic button | Stop recording, send to server |
| **Escape** | Dismiss window without sending |
| Drag window background | Move the window |
| Tray → Launch at Login | Toggle autostart |
| Tray → Quit | Exit completely |

---

## Project structure

```
tasksnap-desktop/
├── src/
│   ├── App.tsx          # UI: record button, states, send logic
│   ├── main.tsx         # React entry point
│   └── index.css        # Tailwind + transparent body
├── src-tauri/
│   ├── src/
│   │   ├── lib.rs       # Tray, global shortcut, window logic
│   │   └── main.rs      # Binary entry point
│   ├── icons/           # App icons (replace with your own)
│   ├── capabilities/
│   │   └── default.json # Tauri v2 permission grants
│   └── tauri.conf.json  # Window config, bundle config
├── .env                 # Your Supabase URL (git-ignored)
└── vite.config.ts
```

---

## Customising icons

Run with any 1024×1024 PNG to regenerate all formats:
```bash
npm run tauri icon path/to/your-icon.png
```

This produces `32x32.png`, `128x128.png`, `128x128@2x.png`, `icon.icns`, and `icon.ico` automatically.

---

## Changing the shortcut

In `src-tauri/src/lib.rs`, find:
```rust
let shortcut = Shortcut::new(Some(Modifiers::CONTROL), Code::Space);
```

Change `Modifiers::CONTROL` / `Code::Space` to your desired key combo.
Available modifiers: `ALT`, `SHIFT`, `SUPER` (Win/Cmd), `CONTROL`.
Available codes: any `Code::*` from the [keyboard-types crate](https://docs.rs/keyboard-types).
