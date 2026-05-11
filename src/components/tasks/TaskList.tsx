import { AnimatePresence } from "framer-motion";
import { TaskCard } from "./TaskCard";
import type { Task } from "@/lib/tasks";

export function TaskList({ tasks, empty, onOpen }: { tasks: Task[]; empty?: string; onOpen?: (t: Task) => void }) {
  if (tasks.length === 0) {
    return (
      <div className="rounded-2xl border border-dashed border-border/60 px-6 py-16 text-center">
        <p className="text-sm text-muted-foreground">{empty ?? "Intet her endnu."}</p>
      </div>
    );
  }
  return (
    <div className="flex flex-col gap-2.5">
      <AnimatePresence mode="popLayout">
        {tasks.map((t) => <TaskCard key={t.id} task={t} onOpen={onOpen} />)}
      </AnimatePresence>
    </div>
  );
}
