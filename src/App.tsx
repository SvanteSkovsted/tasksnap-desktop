import { useCallback, useEffect, useRef, useState } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { listen } from "@tauri-apps/api/event";
import { invoke } from "@tauri-apps/api/core";
import { clearAuth, getAuth } from "./auth";
import { Waveform } from "./Waveform";

type AppState      = "idle" | "recording" | "sending" | "success" | "error";
type RecordingMode = "click" | "hold";

const ENDPOINT = import.meta.env.VITE_SUPABASE_URL as string;

const MODE_KEY = "tasksnap_recording_mode";

// ── Palette ──────────────────────────────────────────────────────────────────

const C = {
  bg:        "linear-gradient(155deg, #F9F4ED 0%, #F2EDE3 100%)",
  border:    "rgba(210, 196, 175, 0.65)",
  innerHi:   "rgba(255,255,255,0.88)",
  innerLo:   "rgba(180,163,140,0.28)",
  textPrime: "#2C2420",
  textSub:   "#9B8B7A",
  textMuted: "#C0AF9C",
  micIdle:   "linear-gradient(145deg, #EDE5D8 0%, #E2D6C5 100%)",
  micRecord: "linear-gradient(145deg, #D4845A 0%, #C06840 100%)",
  micSend:   "linear-gradient(145deg, #EDE5D8 0%, #E2D6C5 100%)",
  micOk:     "linear-gradient(145deg, #8DB07E 0%, #739A64 100%)",
  micErr:    "linear-gradient(145deg, #D4845A 0%, #C06840 100%)",
  iconIdle:  "#A8926A",
  iconWarm:  "#FDF8F3",
};

// ── Helpers ───────────────────────────────────────────────────────────────────

function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve((reader.result as string).split(",")[1]);
    reader.onerror   = reject;
    reader.readAsDataURL(blob);
  });
}

function loadMode(): RecordingMode {
  return (localStorage.getItem(MODE_KEY) as RecordingMode) ?? "click";
}

// ── Component ─────────────────────────────────────────────────────────────────

export default function App() {
  const [appState,     setAppState]     = useState<AppState>("idle");
  const [errorMsg,     setErrorMsg]     = useState("");
  const [visible,      setVisible]      = useState(false);
  const [recordingMode, setRecordingMode] = useState<RecordingMode>(loadMode);
  const [analyser,     setAnalyser]     = useState<AnalyserNode | null>(null);
  const [dotCount,     setDotCount]     = useState(0);

  // Refs for values that shortcut / event callbacks must read without stale closures
  const recorderRef      = useRef<MediaRecorder | null>(null);
  const chunksRef        = useRef<Blob[]>([]);
  const streamRef        = useRef<MediaStream | null>(null);
  const audioCtxRef      = useRef<AudioContext | null>(null);
  const isRecordingRef   = useRef(false);
  const windowShownRef   = useRef(false);
  const recordingModeRef = useRef<RecordingMode>(loadMode());

  // Keep ref in sync with state (avoids stale closures in listen callbacks)
  useEffect(() => { recordingModeRef.current = recordingMode; }, [recordingMode]);

  // ── Entrance animation ───────────────────────────────────────────────────
  useEffect(() => {
    const id = requestAnimationFrame(() => {
      windowShownRef.current = true;
      setVisible(true);
    });
    // Sync initial recording mode to Rust on every mount
    invoke("set_recording_mode", { hold: recordingModeRef.current === "hold" });
    return () => cancelAnimationFrame(id);
  }, []);

  // ── Close with exit transition ───────────────────────────────────────────
  const closeWindow = useCallback(async () => {
    if (!windowShownRef.current) return;
    windowShownRef.current = false;
    setVisible(false);
    await new Promise<void>((r) => setTimeout(r, 220));
    await getCurrentWindow().hide();
    setAppState("idle");
    setErrorMsg("");
    setAnalyser(null);
    audioCtxRef.current?.close();
    audioCtxRef.current = null;
  }, []);

  // ── Recording core ────────────────────────────────────────────────────────
  const startRecording = useCallback(async () => {
    if (isRecordingRef.current) return;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
      streamRef.current = stream;

      // MediaRecorder for actual audio capture
      const recorder = new MediaRecorder(stream);
      chunksRef.current = [];
      recorder.ondataavailable = (e) => {
        console.log("[TaskSnap] chunk:", e.data.size, "bytes");
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      recorder.start();
      console.log("[TaskSnap] recorder started — mimeType:", recorder.mimeType);
      recorderRef.current    = recorder;

      // AudioContext + AnalyserNode for waveform visualisation
      const audioCtx            = new AudioContext();
      const analyserNode        = audioCtx.createAnalyser();
      analyserNode.fftSize      = 256;          // 128 frequency bins
      analyserNode.minDecibels  = -90;          // raise floor — picks up quiet speech
      analyserNode.maxDecibels  = -10;          // raise ceiling — full dynamic range
      analyserNode.smoothingTimeConstant = 0.8;
      audioCtx.createMediaStreamSource(stream).connect(analyserNode);
      audioCtxRef.current  = audioCtx;
      setAnalyser(analyserNode);

      isRecordingRef.current = true;
      setAppState("recording");
    } catch {
      setErrorMsg("Microphone access denied");
      setAppState("error");
      setTimeout(closeWindow, 2000);
    }
  }, [closeWindow]);

  const stopAndSend = useCallback(async () => {
    if (!isRecordingRef.current) return;
    isRecordingRef.current = false;
    setAppState("sending");
    setAnalyser(null); // freeze waveform

    const recorder = recorderRef.current!;
    const stopped  = new Promise<void>((resolve) => {
      recorder.onstop = () => {
        console.log("[TaskSnap] onstop — chunks:", chunksRef.current.length);
        audioCtxRef.current?.close();
        audioCtxRef.current = null;
        resolve();
      };
    });
    recorder.stop();
    streamRef.current?.getTracks().forEach((t) => t.stop());
    await stopped;

    const auth = getAuth();
    if (!auth) { await invoke("session_expired"); return; }

    console.log("[TaskSnap] chunk sizes:", chunksRef.current.map((c) => c.size));
    const blob = new Blob(chunksRef.current, { type: "audio/webm" });
    console.log("[TaskSnap] blob:", blob.size, "bytes");

    try {
      const base64 = await blobToBase64(blob);
      console.log("[TaskSnap] base64 length:", base64.length);
      console.log("[TaskSnap] POST →", ENDPOINT);

      const res = await fetch(ENDPOINT, {
        method:  "POST",
        headers: { "Content-Type": "application/json" },
        body:    JSON.stringify({ audio_base64: base64, mime_type: "audio/webm", user_id: auth.userId }),
      });

      if (res.status === 401) { clearAuth(); await invoke("session_expired"); return; }

      if (!res.ok) {
        const body = await res.text();
        console.error(`[TaskSnap] ${res.status}\n${body}`);
        throw new Error(body || `Server error ${res.status}`);
      }

      setAppState("success");
      setTimeout(closeWindow, 900);
    } catch (err) {
      setErrorMsg(err instanceof Error ? err.message : "Failed to send");
      setAppState("error");
      setTimeout(closeWindow, 2500);
    }
  }, [closeWindow]);

  // ── Tauri event listeners ────────────────────────────────────────────────
  useEffect(() => {
    const cleanup: Array<() => void> = [];

    // Click mode: re-run entrance animation on each Ctrl+Space show.
    // Hold mode: shortcut-pressed handles the show instead.
    listen("tauri://focus", () => {
      if (windowShownRef.current) return;
      if (recordingModeRef.current === "hold") {
        // window was shown by Rust already, just arm visible
        windowShownRef.current = true;
        setVisible(true);
        return;
      }
      windowShownRef.current = true;
      setAppState("idle");
      setErrorMsg("");
      setVisible(false);
      requestAnimationFrame(() => requestAnimationFrame(() => setVisible(true)));
    }).then((fn) => cleanup.push(fn));

    // Hold mode: Ctrl+Space key-down → show window + start recording
    listen("shortcut-pressed", () => {
      if (recordingModeRef.current !== "hold") return;
      // Window is already shown by Rust before this event fires
      windowShownRef.current = true;
      setVisible(true);
      startRecording();
    }).then((fn) => cleanup.push(fn));

    // Hold mode: Ctrl+Space key-up → stop + send
    listen("shortcut-released", () => {
      if (recordingModeRef.current !== "hold") return;
      stopAndSend();
    }).then((fn) => cleanup.push(fn));

    // Tray menu toggled the recording mode
    listen<boolean>("recording-mode-changed", (event) => {
      const isHold = event.payload;
      const mode: RecordingMode = isHold ? "hold" : "click";
      localStorage.setItem(MODE_KEY, mode);
      recordingModeRef.current = mode;
      setRecordingMode(mode);
    }).then((fn) => cleanup.push(fn));

    listen("keydown", (e: { payload: string }) => {
      if (e.payload === "Escape") closeWindow();
    }).then((fn) => cleanup.push(fn));

    return () => cleanup.forEach((fn) => fn());
  }, [startRecording, stopAndSend, closeWindow]);

  // Escape via DOM (webview captures it directly)
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === "Escape") closeWindow(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [closeWindow]);

  // ── Mic click (click mode only) ──────────────────────────────────────────
  const handleMicClick = async () => {
    if (recordingMode === "click") {
      if (appState === "idle")      await startRecording();
      else if (appState === "recording") await stopAndSend();
    }
  };

  // ── "Analyzing…" dot cycle while sending ────────────────────────────────
  useEffect(() => {
    if (appState !== "sending") { setDotCount(0); return; }
    const id = setInterval(() => setDotCount((n) => (n + 1) % 4), 380);
    return () => clearInterval(id);
  }, [appState]);

  // ── Derived values ────────────────────────────────────────────────────────
  const isHoldMode = recordingMode === "hold";

  const micGradient = { idle: C.micIdle, recording: C.micRecord, sending: C.micSend, success: C.micOk, error: C.micErr }[appState];
  const micShadow   = appState === "recording"
    ? "0 8px 28px rgba(196,104,64,0.45), 0 2px 8px rgba(196,104,64,0.25)"
    : "0 4px 18px rgba(0,0,0,0.09), 0 1px 4px rgba(0,0,0,0.06), inset 0 1px 0 rgba(255,255,255,0.72)";

  const dots        = ".".repeat(dotCount);
  const statusLabel = {
    idle:      "Ready",
    recording: "Recording",
    sending:   `Analyzing${dots}`,
    success:   "Done",
    error:     "Error",
  }[appState];
  const hintLabel   = {
    idle:      isHoldMode ? "Hold Ctrl+Space" : "Tap to start",
    recording: isHoldMode ? "Release to send" : "Tap to send",
    sending:   "",
    success:   "",
    error:     errorMsg,
  }[appState];

  // Spring in / ease-out exit.  Hold mode slides up rather than scaling.
  const containerStyle: React.CSSProperties = isHoldMode
    ? {
        opacity:    visible ? 1 : 0,
        transform:  visible ? "translateY(0px)" : "translateY(16px)",
        transition: visible
          ? "opacity 0.20s ease-out, transform 0.30s cubic-bezier(0.34,1.56,0.64,1)"
          : "opacity 0.16s ease-in,  transform 0.16s ease-in",
        willChange: "opacity, transform",
      }
    : {
        opacity:    visible ? 1 : 0,
        transform:  visible ? "scale(1) translateY(0px)" : "scale(0.92) translateY(14px)",
        transition: visible
          ? "opacity 0.28s ease-out, transform 0.42s cubic-bezier(0.34,1.56,0.64,1)"
          : "opacity 0.19s ease-in,  transform 0.19s ease-in",
        willChange: "opacity, transform",
      };

  // ── Hold mode UI (300 × 110, bottom-right) ───────────────────────────────
  if (isHoldMode) {
    return (
      <div style={containerStyle} className="w-full h-full">
        <div
          className="w-full h-full flex flex-col relative overflow-hidden"
          style={{
            background:           C.bg,
            borderRadius:         "20px",
            border:               `1px solid ${C.border}`,
            backdropFilter:       "blur(40px) saturate(160%)",
            WebkitBackdropFilter: "blur(40px) saturate(160%)",
            boxShadow:            `inset 0 1px 0 ${C.innerHi}, inset 0 -1px 0 ${C.innerLo}`,
          }}
          data-tauri-drag-region
        >
          {/* Waveform — the whole window */}
          <div className="flex-1 flex items-center justify-center px-3 pt-3">
            <Waveform
              analyser={analyser}
              isRecording={appState === "recording"}
              isSending={appState === "sending"}
              width={268}
              height={54}
              barCount={42}
            />
          </div>

          {/* Status row */}
          <div className="flex items-center justify-between px-4 pb-[10px] shrink-0">
            <span style={{ color: C.textPrime, fontSize: "12px", fontWeight: 500, letterSpacing: "-0.01em" }}>
              {statusLabel}
            </span>
            <span style={{ color: C.textSub, fontSize: "10px" }}>
              {hintLabel}
            </span>
          </div>
        </div>
      </div>
    );
  }

  // ── Click mode UI (320 × 260, centred) ──────────────────────────────────
  return (
    <div style={containerStyle} className="w-full h-full">
      <div
        className="w-full h-full flex flex-col relative overflow-hidden"
        style={{
          background:           C.bg,
          borderRadius:         "28px",
          border:               `1px solid ${C.border}`,
          backdropFilter:       "blur(40px) saturate(160%)",
          WebkitBackdropFilter: "blur(40px) saturate(160%)",
          boxShadow:            `inset 0 1px 0 ${C.innerHi}, inset 0 -1px 0 ${C.innerLo}`,
        }}
        data-tauri-drag-region
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 pt-[18px] pb-1 shrink-0">
          <span style={{ color: C.textMuted, fontSize: "9px", fontWeight: 600, letterSpacing: "0.14em", textTransform: "uppercase" }}>
            TaskSnap
          </span>
          <button
            onClick={closeWindow}
            style={{
              width: "18px", height: "18px", borderRadius: "50%", border: "none",
              background: "rgba(180,163,140,0.18)", color: C.textSub,
              fontSize: "10px", lineHeight: 1, cursor: "pointer",
              display: "flex", alignItems: "center", justifyContent: "center",
              transition: "background 0.15s",
            }}
            onMouseEnter={(e) => (e.currentTarget.style.background = "rgba(180,163,140,0.38)")}
            onMouseLeave={(e) => (e.currentTarget.style.background = "rgba(180,163,140,0.18)")}
          >
            ✕
          </button>
        </div>

        {/* Main */}
        <div className="flex-1 flex flex-col items-center justify-center gap-1">

          {/* Mic button + recording rings */}
          <div className="relative flex items-center justify-center mb-3">
            {appState === "recording" && (
              <> <div className="ring ring-1" /> <div className="ring ring-2" /> <div className="ring ring-3" /> </>
            )}
            <button
              className="mic-btn"
              onClick={handleMicClick}
              disabled={appState === "sending" || appState === "success" || appState === "error"}
              style={{
                position: "relative", zIndex: 10,
                width: "76px", height: "76px", borderRadius: "50%", border: "none",
                background:  micGradient,
                boxShadow:   micShadow,
                cursor:      (appState === "idle" || appState === "recording") ? "pointer" : "default",
                display: "flex", alignItems: "center", justifyContent: "center",
                transition:  "background 0.3s ease, box-shadow 0.3s ease, transform 0.25s cubic-bezier(0.34,1.56,0.64,1)",
                transform:   appState === "recording" ? "scale(1.06)" : "scale(1)",
              }}
            >
              {appState === "sending"   && <SpinnerIcon />}
              {appState === "success"   && <CheckIcon   color={C.iconWarm} />}
              {appState === "error"     && <XIcon       color={C.iconWarm} />}
              {(appState === "idle" || appState === "recording") && (
                <MicIcon color={appState === "recording" ? C.iconWarm : C.iconIdle} />
              )}
            </button>
          </div>

          {/* Status */}
          <p style={{ margin: 0, color: C.textPrime, fontSize: "15px", fontWeight: 500, letterSpacing: "-0.015em" }}>
            {statusLabel}
          </p>

          {/* Hint / error */}
          <p style={{
            margin: "4px 0 0", color: appState === "error" ? "#C06840" : C.textSub,
            fontSize: "11px", lineHeight: 1, maxWidth: "240px",
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            minHeight: "13px", textAlign: "center",
          }}>
            {hintLabel}
          </p>

          {/* Waveform — shown during recording and in idle (gentle wave) */}
          <div
            style={{
              marginTop:  "12px",
              opacity:    appState === "recording" ? 1 : 0.55,
              transition: "opacity 0.4s ease",
            }}
          >
            <Waveform
              analyser={analyser}
              isRecording={appState === "recording"}
              isSending={appState === "sending"}
              width={256}
              height={44}
              barCount={38}
            />
          </div>
        </div>

        {/* Footer */}
        <div className="shrink-0 pb-[14px] text-center">
          <span style={{ color: C.textMuted, fontSize: "9px", letterSpacing: "0.04em" }}>
            {appState === "idle" ? "esc to dismiss" : ""}
          </span>
        </div>
      </div>
    </div>
  );
}

// ─── Icons ────────────────────────────────────────────────────────────────────

function MicIcon({ color }: { color: string }) {
  return (
    <svg width="30" height="30" viewBox="0 0 24 24" fill={color}>
      <path d="M12 1a4 4 0 0 1 4 4v6a4 4 0 0 1-8 0V5a4 4 0 0 1 4-4zm0 2a2 2 0 0 0-2 2v6a2 2 0 0 0 4 0V5a2 2 0 0 0-2-2zm7 8a1 1 0 0 1 0 2 7 7 0 0 1-14 0 1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 0 1 2 0zm-7 7a1 1 0 0 1 1 1v2a1 1 0 1 1-2 0v-2a1 1 0 0 1 1-1z" />
    </svg>
  );
}
function CheckIcon({ color }: { color: string }) {
  return (
    <svg width="30" height="30" viewBox="0 0 24 24" fill="none"
      stroke={color} strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}
function XIcon({ color }: { color: string }) {
  return (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none"
      stroke={color} strokeWidth={2.5} strokeLinecap="round">
      <line x1="18" y1="6" x2="6" y2="18" />
      <line x1="6" y1="6" x2="18" y2="18" />
    </svg>
  );
}
function SpinnerIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none"
      style={{ animation: "spin 0.9s linear infinite" }}>
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      <circle cx="12" cy="12" r="10" stroke={C.iconIdle} strokeWidth="3" opacity="0.25" />
      <path fill={C.iconIdle} opacity="0.8" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
    </svg>
  );
}
