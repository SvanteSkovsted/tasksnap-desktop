import { createFileRoute } from "@tanstack/react-router";
import { addDays, format, isSameDay, startOfWeek } from "date-fns";
import { da } from "date-fns/locale";
import { AppShell } from "@/components/tasks/AppShell";
import { priorityClass } from "@/lib/tasks";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/calendar")({ component: CalendarView });

function CalendarView() {
  const start = startOfWeek(new Date(), { weekStartsOn: 1 });
  const days = Array.from({ length: 7 }, (_, i) => addDays(start, i));

  return (
    <AppShell title="Kalender" subtitle="Denne uge i overblik.">
      {({ tasks, openTask }) => {
        const scheduled = tasks.filter((t) => t.due_date && t.status !== "done");
        return (
          <div className="frosted overflow-hidden rounded-2xl">
            <div className="grid grid-cols-7 border-b border-border/60 bg-surface/40">
              {days.map((d) => (
                <div key={d.toISOString()} className="border-r border-border/60 last:border-r-0 px-3 py-2.5">
                  <div className="text-[10px] uppercase tracking-wider text-muted-foreground capitalize">{format(d, "EEE", { locale: da })}</div>
                  <div className={cn("text-sm font-semibold", isSameDay(d, new Date()) && "text-primary")}>
                    {format(d, "d")}
                  </div>
                </div>
              ))}
            </div>
            <div className="grid grid-cols-7 min-h-[460px]">
              {days.map((d) => {
                const list = scheduled.filter((t) => isSameDay(new Date(t.due_date!), d));
                return (
                  <div key={d.toISOString()} className="border-r border-border/60 last:border-r-0 p-2 space-y-1.5">
                    {list.map((t) => (
                      <button
                        key={t.id}
                        onClick={() => openTask(t)}
                        className={cn("w-full text-left rounded-lg border px-2 py-1.5 text-[11px] hover:scale-[1.02] transition-transform", priorityClass(t.priority))}
                      >
                        <div className="font-semibold text-foreground line-clamp-2">{t.title}</div>
                        <div className="mt-0.5 text-muted-foreground">{format(new Date(t.due_date!), "HH:mm")}</div>
                      </button>
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
