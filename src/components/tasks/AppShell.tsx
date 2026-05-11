import { useEffect, useState } from "react";
import { useNavigate } from "@tanstack/react-router";
import { useAuth } from "@/lib/use-auth";
import { supabase } from "@/integrations/supabase/client";
import type { Task } from "@/lib/tasks";
import { Sidebar } from "./Sidebar";

export function AppShell({ children, title, subtitle }: { children: (ctx: { tasks: Task[]; userId: string }) => React.ReactNode; title: string; subtitle?: string }) {
  const { user, loading } = useAuth();
  const nav = useNavigate();
  const [tasks, setTasks] = useState<Task[]>([]);

  useEffect(() => {
    if (!loading && !user) nav({ to: "/auth" });
  }, [loading, user, nav]);

  useEffect(() => {
    if (!user) return;
    let mounted = true;
    const load = async () => {
      const { data } = await supabase
        .from("tasks")
        .select("*")
        .order("created_at", { ascending: false });
      if (mounted && data) setTasks(data as Task[]);
    };
    load();
    const channel = supabase.channel("tasks-rt")
      .on("postgres_changes", { event: "*", schema: "public", table: "tasks" }, () => load())
      .subscribe();
    return () => { mounted = false; supabase.removeChannel(channel); };
  }, [user]);

  if (loading || !user) {
    return <div className="flex h-screen items-center justify-center text-muted-foreground text-sm">Loading…</div>;
  }

  return (
    <div className="flex h-screen w-full bg-background">
      <Sidebar email={user.email ?? ""} />
      <main className="flex-1 overflow-y-auto">
        <div className="mx-auto max-w-3xl px-6 py-10">
          <header className="mb-8">
            <h1 className="text-2xl font-semibold tracking-tight text-balance">{title}</h1>
            {subtitle && <p className="mt-1 text-sm text-muted-foreground">{subtitle}</p>}
          </header>
          {children({ tasks, userId: user.id })}
        </div>
      </main>
    </div>
  );
}