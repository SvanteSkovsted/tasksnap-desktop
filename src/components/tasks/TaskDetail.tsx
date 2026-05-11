import { useEffect, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { format } from "date-fns";
import { Trash2, X, Mic } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { type Task, PRIORITY_LABEL } from "@/lib/tasks";
import { Button } from "@/components/ui/button";

type Patch = Partial<Pick<Task, "title" | "description" | "priority" | "category" | "due_date" | "reminder_minutes" | "status">>;

export function TaskDetail({ task, onClose }: { task: Task | null; onClose: () => void }) {
  const [draft, setDraft] = useState<Task | null>(task);

  useEffect(() => { setDraft(task); }, [task]);

  const update = (patch: Patch) => {
    if (!draft) return;
    setDraft({ ...draft, ...patch } as Task);
  };

  const save = async () => {
    if (!draft) return;
    await supabase.from("tasks").update({
      title: draft.title,
      description: draft.description,
      priority: draft.priority,
      category: draft.category,
      due_date: draft.due_date,
      reminder_minutes: draft.reminder_minutes,
      status: draft.status,
    }).eq("id", draft.id);
    onClose();
  };

  const remove = async () => {
    if (!draft) return;
    await supabase.from("tasks").delete().eq("id", draft.id);
    onClose();
  };

  const dueLocal = draft?.due_date
    ? format(new Date(draft.due_date), "yyyy-MM-dd'T'HH:mm")
    : "";

  return (
    <AnimatePresence>
      {draft && (
        <>
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            transition={{ duration: 0.18 }}
            onClick={onClose}
            className="fixed inset-0 z-40 bg-foreground/10 backdrop-blur-sm"
          />
          <motion.aside
            initial={{ x: "100%" }} animate={{ x: 0 }} exit={{ x: "100%" }}
            transition={{ type: "spring", stiffness: 280, damping: 32 }}
            className="fixed right-0 top-0 z-50 h-screen w-full max-w-md frosted-strong p-6 overflow-y-auto"
          >
            <div className="mb-5 flex items-center justify-between">
              <span className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">Opgavedetaljer</span>
              <button onClick={onClose} className="rounded-md p-1.5 text-muted-foreground hover:bg-accent hover:text-foreground">
                <X className="h-4 w-4" />
              </button>
            </div>

            <Field label="Titel">
              <input
                value={draft.title}
                onChange={(e) => update({ title: e.target.value })}
                className="w-full rounded-lg border border-border bg-background/50 px-3 py-2 text-sm font-medium focus:border-primary/60 focus:outline-none"
              />
            </Field>

            {draft.summary && (
              <Field label="Resume">
                <p className="text-[13px] text-muted-foreground leading-relaxed">{draft.summary}</p>
              </Field>
            )}

            {(draft.transcript || draft.description) && (
              <Field label={<span className="inline-flex items-center gap-1.5"><Mic className="h-3 w-3" />Transskript</span>}>
                <div className="rounded-lg border border-border/60 bg-background/40 px-3 py-2.5 text-[13px] text-muted-foreground italic leading-relaxed whitespace-pre-wrap">
                  {draft.transcript || draft.description}
                </div>
              </Field>
            )}

            <div className="grid grid-cols-2 gap-3">
              <Field label="Prioritet">
                <select
                  value={draft.priority}
                  onChange={(e) => update({ priority: e.target.value as Task["priority"] })}
                  className="w-full rounded-lg border border-border bg-background/50 px-3 py-2 text-sm focus:border-primary/60 focus:outline-none"
                >
                  {(["urgent","high","medium","low"] as const).map((p) => (
                    <option key={p} value={p}>{PRIORITY_LABEL[p]}</option>
                  ))}
                </select>
              </Field>
              <Field label="Kategori">
                <input
                  value={draft.category ?? ""}
                  onChange={(e) => update({ category: e.target.value })}
                  className="w-full rounded-lg border border-border bg-background/50 px-3 py-2 text-sm focus:border-primary/60 focus:outline-none"
                />
              </Field>
            </div>

            <Field label="Forfaldsdato">
              <input
                type="datetime-local"
                value={dueLocal}
                onChange={(e) => update({ due_date: e.target.value ? new Date(e.target.value).toISOString() : null })}
                className="w-full rounded-lg border border-border bg-background/50 px-3 py-2 text-sm focus:border-primary/60 focus:outline-none"
              />
            </Field>

            <Field label="Påmindelse">
              <select
                value={draft.reminder_minutes ?? ""}
                onChange={(e) => update({ reminder_minutes: e.target.value ? Number(e.target.value) : null })}
                className="w-full rounded-lg border border-border bg-background/50 px-3 py-2 text-sm focus:border-primary/60 focus:outline-none"
              >
                <option value="">Ingen</option>
                <option value="15">15 minutter før</option>
                <option value="60">1 time før</option>
                <option value="1440">Dagen før</option>
              </select>
            </Field>

            <div className="mt-6 flex items-center gap-2">
              <Button onClick={save} className="flex-1">Gem ændringer</Button>
              <button
                onClick={remove}
                className="flex h-9 w-9 items-center justify-center rounded-lg border border-border text-muted-foreground hover:border-destructive hover:text-destructive transition-colors"
                aria-label="Slet opgave"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
}

function Field({ label, children }: { label: React.ReactNode; children: React.ReactNode }) {
  return (
    <div className="mb-4">
      <div className="mb-1.5 text-[11px] font-medium uppercase tracking-wider text-muted-foreground">{label}</div>
      {children}
    </div>
  );
}
