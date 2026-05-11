import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Sparkles, Mic, Download, Check, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { supabase } from "@/integrations/supabase/client";
import { completeOnboarding, getOnboardingStatus, ensurePermission } from "@/lib/notifications";

export function Onboarding({ userId }: { userId: string }) {
  const [step, setStep] = useState(0);
  const [open, setOpen] = useState(false);
  const [firstTask, setFirstTask] = useState("");

  useEffect(() => {
    let mounted = true;
    getOnboardingStatus(userId).then((done) => { if (mounted && !done) setOpen(true); });
    return () => { mounted = false; };
  }, [userId]);

  const finish = async () => {
    await completeOnboarding(userId);
    setOpen(false);
  };

  const createFirst = async () => {
    if (!firstTask.trim()) { setStep(2); return; }
    await supabase.from("tasks").insert({
      user_id: userId,
      title: firstTask.trim(),
      priority: "medium",
      category: "Indbakke",
    });
    setFirstTask("");
    setStep(2);
  };

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-foreground/20 backdrop-blur-md"
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.96, y: 8 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.96, y: 8 }}
            transition={{ type: "spring", stiffness: 240, damping: 26 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 pointer-events-none"
          >
            <div className="frosted-strong w-full max-w-md rounded-3xl p-8 pointer-events-auto">
              <div className="mb-5 flex items-center gap-1.5">
                {[0, 1, 2].map((i) => (
                  <div key={i} className={`h-1 flex-1 rounded-full transition-colors ${i <= step ? "bg-primary" : "bg-border"}`} />
                ))}
              </div>

              {step === 0 && (
                <Step
                  icon={<Sparkles className="h-5 w-5" />}
                  title="Velkommen til TaskSnap"
                  body="Optag dine opgaver med stemmen og lad AI strukturere dem for dig — titel, resume, prioritet og forfaldsdato. Lad os komme i gang."
                  action={<Button onClick={async () => { await ensurePermission(); setStep(1); }} className="w-full">
                    Aktivér påmindelser <ArrowRight className="ml-1.5 h-4 w-4" />
                  </Button>}
                />
              )}

              {step === 1 && (
                <Step
                  icon={<Mic className="h-5 w-5" />}
                  title="Opret din første opgave"
                  body="Skriv noget du skal huske. Senere kan du optage dem direkte fra desktop-appen."
                  action={
                    <div className="space-y-3">
                      <input
                        autoFocus
                        value={firstTask}
                        onChange={(e) => setFirstTask(e.target.value)}
                        onKeyDown={(e) => e.key === "Enter" && createFirst()}
                        placeholder="fx Ring til Anne om mandagens møde"
                        className="w-full rounded-lg border border-border bg-background/50 px-3 py-2.5 text-sm focus:border-primary/60 focus:outline-none"
                      />
                      <div className="flex gap-2">
                        <button onClick={() => setStep(2)} className="flex-1 rounded-lg border border-border px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors">Spring over</button>
                        <Button onClick={createFirst} className="flex-1">Opret <ArrowRight className="ml-1.5 h-4 w-4" /></Button>
                      </div>
                    </div>
                  }
                />
              )}

              {step === 2 && (
                <Step
                  icon={<Download className="h-5 w-5" />}
                  title="Hent desktop-appen"
                  body="Optag opgaver fra hvor som helst på din Mac med en genvej. Web-dashboardet synkroniserer automatisk."
                  action={
                    <div className="space-y-3">
                      <a
                        href="#"
                        onClick={(e) => e.preventDefault()}
                        className="flex w-full items-center justify-center gap-2 rounded-lg border border-border bg-card px-3 py-2.5 text-sm font-medium hover:bg-accent transition-colors"
                      >
                        <Download className="h-4 w-4" /> TaskSnap.dmg (kommer snart)
                      </a>
                      <Button onClick={finish} className="w-full">
                        <Check className="mr-1.5 h-4 w-4" /> Færdig — gå til appen
                      </Button>
                    </div>
                  }
                />
              )}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

function Step({ icon, title, body, action }: { icon: React.ReactNode; title: string; body: string; action: React.ReactNode }) {
  return (
    <motion.div
      key={title}
      initial={{ opacity: 0, x: 12 }} animate={{ opacity: 1, x: 0 }}
      transition={{ type: "spring", stiffness: 260, damping: 24 }}
    >
      <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-xl bg-primary/15 text-primary">{icon}</div>
      <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
      <p className="mt-2 text-sm text-muted-foreground leading-relaxed">{body}</p>
      <div className="mt-6">{action}</div>
    </motion.div>
  );
}
