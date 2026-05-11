import { createFileRoute } from "@tanstack/react-router";
import { isToday, isPast } from "date-fns";
import { AppShell } from "@/components/tasks/AppShell";
import { TaskList } from "@/components/tasks/TaskList";
import { QuickAdd } from "@/components/tasks/QuickAdd";
import { PRIORITY_ORDER } from "@/lib/tasks";

export const Route = createFileRoute("/")({ component: Today });

function Today() {
  return (
    <AppShell title="I dag" subtitle="Fokuser på det vigtigste lige nu.">
      {({ tasks, userId, openTask }) => {
        const open = tasks.filter((t) => t.status !== "done");
        const today = open.filter((t) => {
          if (!t.due_date) return false;
          return isToday(new Date(t.due_date)) || isPast(new Date(t.due_date));
        });
        const noDate = open.filter((t) => !t.due_date);
        const sort = (a: typeof open[number], b: typeof open[number]) =>
          PRIORITY_ORDER[a.priority] - PRIORITY_ORDER[b.priority];

        return (
          <div className="space-y-10">
            <QuickAdd userId={userId} />
            <section>
              <SectionLabel count={today.length}>Forfalder i dag &amp; forsinkede</SectionLabel>
              <TaskList tasks={today.sort(sort)} empty="Du er på toppen af det hele." onOpen={openTask} />
            </section>
            <section>
              <SectionLabel count={noDate.length}>Indbakke</SectionLabel>
              <TaskList tasks={noDate.sort(sort)} empty="Ingen utriagerede opgaver." onOpen={openTask} />
            </section>
          </div>
        );
      }}
    </AppShell>
  );
}

function SectionLabel({ children, count }: { children: React.ReactNode; count: number }) {
  return (
    <div className="mb-3 flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.08em] text-muted-foreground">
      <span>{children}</span>
      <span className="rounded bg-muted px-1.5 py-0.5 font-mono text-[10px]">{count}</span>
    </div>
  );
}
