import { useState } from "react";
import { Plus } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";

export function QuickAdd({ userId }: { userId: string }) {
  const [title, setTitle] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim()) return;
    setBusy(true);
    await supabase.from("tasks").insert({
      user_id: userId,
      title: title.trim(),
      priority: "medium",
      category: "Inbox",
    });
    setTitle("");
    setBusy(false);
  };

  return (
    <form onSubmit={submit} className="flex items-center gap-2 rounded-xl border border-border bg-surface px-3.5 py-2.5 transition-colors focus-within:border-primary/60">
      <Plus className="h-4 w-4 flex-none text-muted-foreground" />
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Add a task — or capture by voice from the desktop app"
        disabled={busy}
        className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground/70 focus:outline-none"
      />
      <kbd className="hidden sm:inline-flex items-center rounded border border-border bg-background px-1.5 py-0.5 font-mono text-[10px] text-muted-foreground">
        ⏎
      </kbd>
    </form>
  );
}