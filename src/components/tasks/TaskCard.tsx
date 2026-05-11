import { useState } from "react";
import { Check, Calendar as CalIcon, Mic, ChevronDown } from "lucide-react";
import { format, isPast, isToday } from "date-fns";
import { da } from "date-fns/locale";
import { motion, AnimatePresence } from "framer-motion";
import { supabase } from "@/integrations/supabase/client";
import { type Task, priorityDot, priorityClass, PRIORITY_LABEL } from "@/lib/tasks";
import { cn } from "@/lib/utils";

export function TaskCard({ task, onOpen }: { task: Task; onOpen?: (t: Task) => void }) {
  const done = task.status === "done";
  const overdue = task.due_date && !done && isPast(new Date(task.due_date)) && !isToday(new Date(task.due_date));
  const [expanded, setExpanded] = useState(false);

  const toggle = async (e: React.MouseEvent) => {
    e.stopPropagation();
    await supabase.from("tasks").update({
      status: done ? "todo" : "done",
      completed_at: done ? null : new Date().toISOString(),
    }).eq("id", task.id);
  };

  const hasMore = !!(task.summary || task.transcript || task.description);

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.97 }}
      transition={{ type: "spring", stiffness: 320, damping: 28 }}
      whileHover={{ y: -1 }}
      onClick={() => onOpen?.(task)}
      className="group frosted relative cursor-pointer rounded-2xl px-4 py-3.5 transition-all duration-200 hover:shadow-[var(--shadow-warm-lg)]"
    >
      <div className="flex items-start gap-3">
        <motion.button
          onClick={toggle}
          whileTap={{ scale: 0.85 }}
          className={cn(
            "mt-0.5 flex h-5 w-5 flex-none items-center justify-center rounded-md border transition-all",
            done
              ? "border-primary bg-primary text-primary-foreground"
              : "border-border hover:border-primary/60 bg-background/40"
          )}
          aria-label={done ? "Markér som ikke færdig" : "Markér som færdig"}
        >
          <AnimatePresence>
            {done && (
              <motion.span initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }} transition={{ type: "spring", stiffness: 500, damping: 22 }}>
                <Check className="h-3 w-3" strokeWidth={3} />
              </motion.span>
            )}
          </AnimatePresence>
        </motion.button>

        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-3">
            <p className={cn(
              "text-[14px] font-semibold leading-snug text-foreground tracking-tight",
              done && "text-muted-foreground line-through"
            )}>
              {task.title}
            </p>
            <span className={cn(
              "flex-none rounded-md border px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wider",
              priorityClass(task.priority)
            )}>
              {PRIORITY_LABEL[task.priority]}
            </span>
          </div>

          {task.summary && (
            <p className={cn("mt-1 text-[13px] text-muted-foreground leading-relaxed", !expanded && "line-clamp-1")}>
              {task.summary}
            </p>
          )}

          <AnimatePresence initial={false}>
            {expanded && (task.transcript || task.description) && (
              <motion.div
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: "auto", opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                transition={{ type: "spring", stiffness: 240, damping: 28 }}
                className="overflow-hidden"
              >
                <div className="mt-2 rounded-lg border border-border/60 bg-background/40 px-3 py-2 text-[12px] text-muted-foreground italic leading-relaxed">
                  <div className="mb-1 flex items-center gap-1.5 not-italic font-medium uppercase tracking-wider text-[10px]">
                    <Mic className="h-3 w-3" /> Transskript
                  </div>
                  {task.transcript || task.description}
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] text-muted-foreground">
            {task.category && (
              <span className="inline-flex items-center gap-1.5">
                <span className={cn("h-1.5 w-1.5 rounded-full", priorityDot(task.priority))} />
                {task.category}
              </span>
            )}
            {task.due_date && (
              <span className={cn("inline-flex items-center gap-1", overdue && "text-priority-urgent")}>
                <CalIcon className="h-3 w-3" />
                {format(new Date(task.due_date), "d. MMM HH:mm", { locale: da })}
              </span>
            )}
            {task.source === "voice" && (
              <span className="inline-flex items-center gap-1 text-primary/80">
                <Mic className="h-3 w-3" />stemme
              </span>
            )}
            {hasMore && (
              <button
                onClick={(e) => { e.stopPropagation(); setExpanded((v) => !v); }}
                className="ml-auto inline-flex items-center gap-0.5 hover:text-foreground transition-colors"
              >
                <ChevronDown className={cn("h-3 w-3 transition-transform", expanded && "rotate-180")} />
                {expanded ? "Skjul" : "Vis mere"}
              </button>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  );
}
