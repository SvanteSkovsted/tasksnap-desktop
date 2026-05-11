import { createFileRoute } from "@tanstack/react-router";
import { AppShell } from "@/components/tasks/AppShell";
import { TaskList } from "@/components/tasks/TaskList";

export const Route = createFileRoute("/completed")({ component: Completed });

function Completed() {
  return (
    <AppShell title="Completed" subtitle="A record of what you've shipped.">
      {({ tasks }) => {
        const done = tasks.filter((t) => t.status === "done").sort((a, b) =>
          new Date(b.completed_at ?? b.updated_at).getTime() - new Date(a.completed_at ?? a.updated_at).getTime()
        );
        return <TaskList tasks={done} empty="No completed tasks yet." />;
      }}
    </AppShell>
  );
}