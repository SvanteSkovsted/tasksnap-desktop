import { createFileRoute } from "@tanstack/react-router";
import { addDays, format, isSameDay, startOfWeek } from "date-fns";
import { AppShell } from "@/components/tasks/AppShell";
import { priorityClass } from "@/lib/tasks";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/calendar")({ component: CalendarView });

function CalendarView() {
  const start = startOfWeek(new Date(), { weekStartsOn: 1 });
  const days = Array.from({ length: 7 }, (_, i) => addDays(start, i));

  return (
    <AppShell title="Calendar" subtitle="This week at a glance.">
      {({ tasks }) => {
        const scheduled = tasks.filter((t) => t.due_date && t.status !== "done");
        return (
          <div className="rounded-xl border border-border bg-card overflow-hidden">
            <div className="grid grid-cols-7 border-b border-border bg-surface">
              {days.map((d) => (
                <div key={d.toISOString()} className="border-r border-border last:border-r-0 px-3 py-2.5">
                  <div className="text-[10px] uppercase tracking-wider text-muted-foreground">{format(d, "EEE")}</div>
                  <div className={cn("text-sm font-medium", isSameDay(d, new Date()) && "text-primary")}>
                    {format(d, "d")}
                  </div>
                </div>
              ))}
            </div>
            <div className="grid grid-cols-7 min-h-[420px]">
              {days.map((d) => {
                const list = scheduled.filter((t) => isSameDay(new Date(t.due_date!), d));
                return (
                  <div key={d.toISOString()} className="border-r border-border last:border-r-0 p-2 space-y-1.5">
                    {list.map((t) => (
                      <div key={t.id} className={cn("rounded-md border px-2 py-1.5 text-[11px]", priorityClass(t.priority))}>
                        <div className="font-medium text-foreground line-clamp-2">{t.title}</div>
                        <div className="mt-0.5 text-muted-foreground">{format(new Date(t.due_date!), "HH:mm")}</div>
                      </div>
                    ))}
                  </div>
                );
              })}
            </div>
          </div>
        );
      }}
    </AppShell>
  );
}