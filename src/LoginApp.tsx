import { useEffect, useRef, useState } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { listen } from "@tauri-apps/api/event";
import { invoke } from "@tauri-apps/api/core";
import { AUTH_KEYS, clearAuth, getAuth } from "./auth";

const SUPABASE_AUTH_URL =
  "https://hxrzqvagvpgyqejvjiil.supabase.co/auth/v1/token?grant_type=password";

const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

type LoginState = "checking" | "idle" | "loading" | "error";

export default function LoginApp() {
  const [loginState, setLoginState] = useState<LoginState>("checking");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errorMsg, setErrorMsg] = useState("");
  const emailRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const auth = getAuth();
    if (auth) {
      // Token already saved — tell Rust the user is authenticated and stay hidden
      invoke("set_authenticated", { value: true }).then(() =>
        getCurrentWindow().hide()
      );
      return;
    }

    // No token — reveal this window and focus the email field
    setLoginState("idle");
    getCurrentWindow()
      .show()
      .then(() => emailRef.current?.focus());

    // Tray "Log Out" emits this event; reset form and stay visible
    const unlisten = listen("do-logout", () => {
      clearAuth();
      setEmail("");
      setPassword("");
      setErrorMsg("");
      setLoginState("idle");
      setTimeout(() => emailRef.current?.focus(), 50);
    });

    return () => {
      unlisten.then((fn) => fn());
    };
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) return;

    setLoginState("loading");
    setErrorMsg("");

    try {
      const res = await fetch(SUPABASE_AUTH_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_ANON_KEY,
        },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(
          data.error_description ?? data.message ?? `Error ${res.status}`
        );
      }

      localStorage.setItem(AUTH_KEYS.TOKEN, data.access_token);
      localStorage.setItem(AUTH_KEYS.USER_ID, data.user.id);

      await invoke("set_authenticated", { value: true });
      await getCurrentWindow().hide();
    } catch (err) {
      setErrorMsg(err instanceof Error ? err.message : "Login failed");
      setLoginState("error");
    }
  };

  // Don't flash UI while we check the existing token
  if (loginState === "checking") return null;

  return (
    <div
      className="w-full h-full bg-gray-900/95 backdrop-blur-xl rounded-2xl border border-white/10 flex flex-col"
      data-tauri-drag-region
    >
      {/* Header */}
      <div className="flex items-center justify-between px-5 pt-4 shrink-0">
        <span className="text-white/30 text-[10px] font-semibold tracking-widest uppercase">
          TaskSnap
        </span>
        <button
          onClick={() => getCurrentWindow().hide()}
          className="w-5 h-5 rounded-full bg-white/10 hover:bg-white/25 flex items-center justify-center text-white/50 hover:text-white transition-all text-xs leading-none"
        >
          ×
        </button>
      </div>

      {/* Icon */}
      <div className="flex justify-center pt-7 pb-4 shrink-0">
        <div className="w-14 h-14 rounded-2xl bg-blue-500/20 border border-blue-500/30 flex items-center justify-center">
          <MicIcon className="w-7 h-7 text-blue-400" />
        </div>
      </div>

      <p className="text-center text-white text-sm font-semibold mb-0.5 shrink-0">
        Sign in to TaskSnap
      </p>
      <p className="text-center text-white/40 text-xs mb-5 shrink-0">
        Use your Supabase account credentials
      </p>

      {/* Form */}
      <form
        onSubmit={handleSubmit}
        className="px-6 flex flex-col gap-3 flex-1 min-h-0"
      >
        <div className="flex flex-col gap-1.5">
          <label className="text-white/50 text-xs font-medium">Email</label>
          <input
            ref={emailRef}
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
            autoComplete="email"
            disabled={loginState === "loading"}
            className="bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white text-sm placeholder:text-white/20 focus:outline-none focus:border-blue-500/60 focus:ring-1 focus:ring-blue-500/30 disabled:opacity-50 transition-colors"
          />
        </div>

        <div className="flex flex-col gap-1.5">
          <label className="text-white/50 text-xs font-medium">Password</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
            autoComplete="current-password"
            disabled={loginState === "loading"}
            className="bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-white text-sm placeholder:text-white/20 focus:outline-none focus:border-blue-500/60 focus:ring-1 focus:ring-blue-500/30 disabled:opacity-50 transition-colors"
          />
        </div>

        {loginState === "error" && errorMsg && (
          <p className="text-red-400 text-xs leading-snug">{errorMsg}</p>
        )}

        <button
          type="submit"
          disabled={loginState === "loading" || !email || !password}
          className="mt-1 w-full py-2.5 rounded-lg bg-blue-600 hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed text-white text-sm font-medium transition-colors flex items-center justify-center gap-2"
        >
          {loginState === "loading" ? (
            <>
              <MiniSpinner />
              Signing in…
            </>
          ) : (
            "Sign In"
          )}
        </button>
      </form>

      <p className="text-center text-white/20 text-[10px] py-4 shrink-0">
        Press Ctrl+Space after signing in
      </p>
    </div>
  );
}

function MicIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 1a4 4 0 0 1 4 4v6a4 4 0 0 1-8 0V5a4 4 0 0 1 4-4zm0 2a2 2 0 0 0-2 2v6a2 2 0 0 0 4 0V5a2 2 0 0 0-2-2zm7 8a1 1 0 0 1 0 2 7 7 0 0 1-14 0 1 1 0 1 1 2 0 5 5 0 0 0 10 0 1 1 0 0 1 2 0zm-7 7a1 1 0 0 1 1 1v2a1 1 0 1 1-2 0v-2a1 1 0 0 1 1-1z" />
    </svg>
  );
}

function MiniSpinner() {
  return (
    <svg className="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none">
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
      />
    </svg>
  );
}
