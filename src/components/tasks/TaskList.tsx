import { TaskCard } from "./TaskCard";
import type { Task } from "@/lib/tasks";

export function TaskList({ tasks, empty }: { tasks: Task[]; empty?: string }) {
  if (tasks.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-border px-6 py-16 text-center">
        <p className="text-sm text-muted-foreground">{empty ?? "Nothing here yet."}</p>
      </div>
    );
  }
  return (
    <div className="flex flex-col gap-2">
      {tasks.map((t) => <TaskCard key={t.id} task={t} />)}
    </div>
  );
}