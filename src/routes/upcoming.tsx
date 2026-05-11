import { createFileRoute } from "@tanstack/react-router";
import { isFuture, isToday, format } from "date-fns";
import { da } from "date-fns/locale";
import { AppShell } from "@/components/tasks/AppShell";
import { TaskList } from "@/components/tasks/TaskList";

export const Route = createFileRoute("/upcoming")({ component: Upcoming });

function Upcoming() {
  return (
    <AppShell title="Kommende" subtitle="Opgaver planlagt forude.">
      {({ tasks, openTask }) => {
        const open = tasks.filter(
          (t) => t.status !== "done" && t.due_date && (isFuture(new Date(t.due_date)) || isToday(new Date(t.due_date)))
        );
        const groups = new Map<string, typeof open>();
        for (const t of open) {
          const k = format(new Date(t.due_date!), "EEEE d. MMM", { locale: da });
          (groups.get(k) ?? groups.set(k, []).get(k)!).push(t);
        }
        const sorted = [...groups.entries()].sort(
          (a, b) => new Date(a[1][0].due_date!).getTime() - new Date(b[1][0].due_date!).getTime()
        );
        if (sorted.length === 0) {
          return <p className="text-sm text-muted-foreground">Intet planlagt.</p>;
        }
        return (
          <div className="space-y-9">
            {sorted.map(([day, items]) => (
              <section key={day}>
                <div className="mb-3 text-[11px] font-semibold uppercase tracking-[0.08em] text-muted-foreground capitalize">{day}</div>
                <TaskList tasks={items} onOpen={openTask} />
              </section>
            ))}
          </div>
        );
      }}
    </AppShell>
  );
}
