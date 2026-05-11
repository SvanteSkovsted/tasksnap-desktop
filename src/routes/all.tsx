import { createFileRoute } from "@tanstack/react-router";
import { useMemo, useState } from "react";
import { Search } from "lucide-react";
import { AppShell } from "@/components/tasks/AppShell";
import { TaskList } from "@/components/tasks/TaskList";
import { PRIORITY_LABEL, PRIORITY_ORDER, type Task } from "@/lib/tasks";

export const Route = createFileRoute("/all")({ component: AllTasks });

function AllTasks() {
  return (
    <AppShell title="Alle opgaver" subtitle="Søg og filtrér på tværs af alt.">
      {({ tasks, openTask }) => <AllTasksView tasks={tasks} openTask={openTask} />}
    </AppShell>
  );
}

function AllTasksView({ tasks, openTask }: { tasks: Task[]; openTask: (t: Task) => void }) {
  const [q, setQ] = useState("");
  const [pri, setPri] = useState<"all" | Task["priority"]>("all");
  const [status, setStatus] = useState<"all" | Task["status"]>("all");

  const filtered = useMemo(() => {
    return tasks
      .filter((t) => (pri === "all" ? true : t.priority === pri))
      .filter((t) => (status === "all" ? true : t.status === status))
      .filter((t) => {
        if (!q.trim()) return true;
        const s = q.toLowerCase();
        return (
          t.title.toLowerCase().includes(s) ||
          (t.summary ?? "").toLowerCase().includes(s) ||
          (t.transcript ?? "").toLowerCase().includes(s) ||
          (t.category ?? "").toLowerCase().includes(s)
        );
      })
      .sort((a, b) => PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority]);
  }, [tasks, q, pri, status]);

  return (
          <div className="space-y-6">
            <div className="frosted flex items-center gap-3 rounded-xl px-4 py-3">
              <Search className="h-4 w-4 text-muted-foreground" />
              <input
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="Søg i titler, resuméer, transskripter…"
                className="flex-1 bg-transparent text-sm focus:outline-none placeholder:text-muted-foreground/70"
              />
            </div>
            <div className="flex flex-wrap gap-2">
              <select value={pri} onChange={(e) => setPri(e.target.value as typeof pri)} className="rounded-lg border border-border bg-card px-3 py-1.5 text-xs">
                <option value="all">Alle prioriteter</option>
                {(["urgent","high","medium","low"] as const).map((p) => <option key={p} value={p}>{PRIORITY_LABEL[p]}</option>)}
              </select>
              <select value={status} onChange={(e) => setStatus(e.target.value as typeof status)} className="rounded-lg border border-border bg-card px-3 py-1.5 text-xs">
                <option value="all">Alle statusser</option>
                <option value="todo">Ikke startet</option>
                <option value="in_progress">I gang</option>
                <option value="done">Færdig</option>
              </select>
            </div>
            <TaskList tasks={filtered} empty="Ingen match." onOpen={openTask} />
          </div>
  );
}
