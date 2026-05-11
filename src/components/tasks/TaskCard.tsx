import { Check, Clock, Calendar as CalIcon, Trash2 } from "lucide-react";
import { format, isPast, isToday } from "date-fns";
import { supabase } from "@/integrations/supabase/client";
import { type Task, priorityDot, priorityClass } from "@/lib/tasks";
import { cn } from "@/lib/utils";

export function TaskCard({ task }: { task: Task }) {
  const done = task.status === "done";
  const overdue = task.due_date && !done && isPast(new Date(task.due_date)) && !isToday(new Date(task.due_date));

  const toggle = async () => {
    await supabase.from("tasks").update({
      status: done ? "todo" : "done",
      completed_at: done ? null : new Date().toISOString(),
    }).eq("id", task.id);
  };

  const remove = async () => {
    await supabase.from("tasks").delete().eq("id", task.id);
  };

  return (
    <div className="group animate-task-in relative flex items-start gap-3 rounded-xl border border-border bg-card px-4 py-3.5 transition-all hover:border-border/80 hover:bg-surface-2">
      <button
        onClick={toggle}
        className={cn(
          "mt-0.5 flex h-5 w-5 flex-none items-center justify-center rounded-md border transition-all",
          done
            ? "border-primary bg-primary text-primary-foreground"
            : "border-border hover:border-primary/60"
        )}
      >
        {done && <Check className="h-3 w-3" strokeWidth={3} />}
      </button>

      <div className="min-w-0 flex-1">
        <div className="flex items-start justify-between gap-3">
          <p className={cn("text-sm font-medium leading-snug text-foreground", done && "text-muted-foreground line-through")}>
            {task.title}
          </p>
          <span className={cn("flex-none rounded-md border px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wider", priorityClass(task.priority))}>
            {task.priority}
          </span>
        </div>
        {task.description && (
          <p className="mt-1 line-clamp-2 text-xs text-muted-foreground">{task.description}</p>
        )}
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
              {format(new Date(task.due_date), "MMM d, HH:mm")}
            </span>
          )}
          {task.source === "voice" && (
            <span className="inline-flex items-center gap-1 text-primary/80">
              <Clock className="h-3 w-3" />voice
            </span>
          )}
        </div>
      </div>

      <button
        onClick={remove}
        className="opacity-0 transition-opacity group-hover:opacity-100 text-muted-foreground hover:text-destructive"
        aria-label="Delete task"
      >
        <Trash2 className="h-4 w-4" />
      </button>
    </div>
  );
}