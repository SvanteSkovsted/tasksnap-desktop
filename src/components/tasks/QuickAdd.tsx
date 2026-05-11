import { useState } from "react";
import { Plus } from "lucide-react";
import { motion } from "framer-motion";
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
      category: "Indbakke",
    });
    setTitle("");
    setBusy(false);
  };

  return (
    <motion.form
      onSubmit={submit}
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 280, damping: 28 }}
      className="frosted flex items-center gap-2.5 rounded-xl px-4 py-3 transition-all duration-200 focus-within:ring-2 focus-within:ring-primary/30"
    >
      <Plus className="h-4 w-4 flex-none text-muted-foreground" />
      <input
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Tilføj en opgave – eller optag den fra desktop-appen"
        disabled={busy}
        className="flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground/70 focus:outline-none"
      />
      <kbd className="hidden sm:inline-flex items-center rounded border border-border bg-background/60 px-1.5 py-0.5 font-mono text-[10px] text-muted-foreground">
        ⏎
      </kbd>
    </motion.form>
  );
}
