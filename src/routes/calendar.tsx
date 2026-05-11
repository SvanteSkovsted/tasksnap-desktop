import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import { addDays, format, isSameDay, startOfWeek, setHours, setMinutes } from "date-fns";
import { da } from "date-fns/locale";
import {
  DndContext,
  useDraggable,
  useDroppable,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from "@dnd-kit/core";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { AppShell } from "@/components/tasks/AppShell";
import { priorityClass, type Task } from "@/lib/tasks";
import { supabase } from "@/integrations/supabase/client";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/calendar")({ component: CalendarView });

function CalendarView() {
  const [weekOffset, setWeekOffset] = useState(0);
  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 6 } }));

  const baseStart = startOfWeek(new Date(), { weekStartsOn: 1 });
  const start = addDays(baseStart, weekOffset * 7);
  const days = Array.from({ length: 7 }, (_, i) => addDays(start, i));

  const handleDragEnd = async (e: DragEndEvent, tasks: Task[]) => {
    if (!e.over) return;
    const task = tasks.find((t) => t.id === e.active.id);
    if (!task) return;
    const targetDay = new Date(e.over.id as string);
    const old = task.due_date ? new Date(task.due_date) : new Date();
    const next = setMinutes(setHours(targetDay, old.getHours() || 9), old.getMinutes());
    if (task.due_date && isSameDay(new Date(task.due_date), next)) return;
    await supabase.from("tasks").update({ due_date: next.toISOString() }).eq("id", task.id);
  };

  return (
    <AppShell title="Kalender" subtitle="Træk opgaver mellem dage for at planlægge.">
      {({ tasks, openTask }) => {
        const scheduled = tasks.filter((t) => t.due_date && t.status !== "done");
        return (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="text-sm font-medium capitalize">
                {format(start, "MMMM yyyy", { locale: da })}
              </div>
              <div className="flex items-center gap-1">
                <button onClick={() => setWeekOffset((w) => w - 1)} className="rounded-md p-1.5 hover:bg-accent text-muted-foreground hover:text-foreground transition-colors">
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <button onClick={() => setWeekOffset(0)} className="rounded-md px-2.5 py-1 text-xs hover:bg-accent text-muted-foreground hover:text-foreground transition-colors">
                  I dag
                </button>
                <button onClick={() => setWeekOffset((w) => w + 1)} className="rounded-md p-1.5 hover:bg-accent text-muted-foreground hover:text-foreground transition-colors">
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            </div>
            <DndContext sensors={sensors} onDragEnd={(e) => handleDragEnd(e, scheduled)}>
              <div className="frosted overflow-hidden rounded-2xl">
                <div className="grid grid-cols-7 border-b border-border/60 bg-surface/40">
                  {days.map((d) => (
                    <div key={d.toISOString()} className="border-r border-border/60 last:border-r-0 px-3 py-2.5">
                      <div className="text-[10px] uppercase tracking-wider text-muted-foreground capitalize">{format(d, "EEE", { locale: da })}</div>
                      <div className={cn("text-sm font-semibold", isSameDay(d, new Date()) && "text-primary")}>{format(d, "d")}</div>
                    </div>
                  ))}
                </div>
                <div className="grid grid-cols-7 min-h-[460px]">
                  {days.map((d) => (
                    <DayCell
                      key={d.toISOString()}
                      day={d}
                      tasks={scheduled.filter((t) => isSameDay(new Date(t.due_date!), d))}
                      onOpen={openTask}
                    />
                  ))}
                </div>
              </div>
            </DndContext>
          </div>
        );
      }}
    </AppShell>
  );
}

function DayCell({ day, tasks, onOpen }: { day: Date; tasks: Task[]; onOpen: (t: Task) => void }) {
  const { setNodeRef, isOver } = useDroppable({ id: day.toISOString() });
  return (
    <div
      ref={setNodeRef}
      className={cn(
        "border-r border-border/60 last:border-r-0 p-2 space-y-1.5 transition-colors",
        isOver && "bg-primary/10"
      )}
    >
      {tasks.map((t) => <CalendarBlock key={t.id} task={t} onOpen={onOpen} />)}
    </div>
  );
}

function CalendarBlock({ task, onOpen }: { task: Task; onOpen: (t: Task) => void }) {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useDraggable({ id: task.id });
  const style: React.CSSProperties = transform
    ? { transform: `translate3d(${transform.x}px, ${transform.y}px, 0)`, zIndex: 50 }
    : {};
  return (
    <div
      ref={setNodeRef}
      style={style}
      {...listeners}
      {...attributes}
      onClick={(e) => { if (!isDragging) { e.stopPropagation(); onOpen(task); } }}
      className={cn(
        "w-full text-left rounded-lg border px-2 py-1.5 text-[11px] cursor-grab active:cursor-grabbing select-none",
        priorityClass(task.priority),
        isDragging && "opacity-70 shadow-[var(--shadow-warm-lg)]"
      )}
    >
      <div className="font-semibold text-foreground line-clamp-2">{task.title}</div>
      <div className="mt-0.5 text-muted-foreground">{format(new Date(task.due_date!), "HH:mm")}</div>
    </div>
  );
}
