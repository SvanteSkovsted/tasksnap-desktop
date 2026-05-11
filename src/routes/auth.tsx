import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Sparkles } from "lucide-react";
import { motion } from "framer-motion";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/lib/use-auth";

export const Route = createFileRoute("/auth")({ component: Auth });

function Auth() {
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const { user } = useAuth();
  const nav = useNavigate();

  useEffect(() => { if (user) nav({ to: "/" }); }, [user, nav]);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true); setError(null);
    const res = mode === "signin"
      ? await supabase.auth.signInWithPassword({ email, password })
      : await supabase.auth.signUp({ email, password, options: { emailRedirectTo: `${window.location.origin}/` } });
    if (res.error) setError(res.error.message);
    setBusy(false);
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center px-4 bg-background">
      <motion.div
        initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}
        transition={{ type: "spring", stiffness: 220, damping: 26 }}
        className="frosted-strong relative w-full max-w-sm rounded-2xl p-8"
      >
        <div className="mb-7 flex items-center gap-2.5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/15 text-primary">
            <Sparkles className="h-4 w-4" />
          </div>
          <span className="text-base font-semibold tracking-tight">TaskSnap</span>
        </div>
        <h1 className="text-2xl font-semibold tracking-tight">{mode === "signin" ? "Velkommen tilbage" : "Opret konto"}</h1>
        <p className="mt-1.5 text-sm text-muted-foreground">Stemmeoptagne opgaver, smukt organiseret.</p>

        <form onSubmit={submit} className="mt-6 space-y-3">
          <input
            type="email" required value={email} onChange={(e) => setEmail(e.target.value)}
            placeholder="dig@arbejde.dk"
            className="w-full rounded-lg border border-border bg-background/50 px-3 py-2.5 text-sm focus:border-primary/60 focus:outline-none"
          />
          <input
            type="password" required minLength={6} value={password} onChange={(e) => setPassword(e.target.value)}
            placeholder="Adgangskode"
            className="w-full rounded-lg border border-border bg-background/50 px-3 py-2.5 text-sm focus:border-primary/60 focus:outline-none"
          />
          {error && <p className="text-xs text-destructive">{error}</p>}
          <button
            type="submit" disabled={busy}
            className="w-full rounded-lg bg-primary px-3 py-2.5 text-sm font-semibold text-primary-foreground transition-all hover:opacity-90 disabled:opacity-50 shadow-[var(--shadow-warm)]"
          >
            {busy ? "…" : mode === "signin" ? "Log ind" : "Opret konto"}
          </button>
        </form>
        <button
          onClick={() => setMode(mode === "signin" ? "signup" : "signin")}
          className="mt-5 text-xs text-muted-foreground hover:text-foreground transition-colors"
        >
          {mode === "signin" ? "Har du ikke en konto? Opret én" : "Har du allerede en konto? Log ind"}
        </button>
      </motion.div>
    </div>
  );
}
