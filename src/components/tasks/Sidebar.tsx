import { Link, useLocation } from "@tanstack/react-router";
import { Inbox, Calendar, CheckCircle2, LogOut, Sparkles } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { cn } from "@/lib/utils";

const items = [
  { to: "/", label: "Today", icon: Inbox },
  { to: "/upcoming", label: "Upcoming", icon: Calendar },
  { to: "/completed", label: "Completed", icon: CheckCircle2 },
  { to: "/calendar", label: "Calendar", icon: Calendar },
] as const;

export function Sidebar({ email }: { email: string }) {
  const loc = useLocation();
  return (
    <aside className="hidden md:flex w-60 flex-col border-r border-border bg-surface/40 px-3 py-5">
      <div className="px-2 mb-6 flex items-center gap-2">
        <div className="flex h-7 w-7 items-center justify-center rounded-md bg-primary/15 text-primary">
          <Sparkles className="h-4 w-4" />
        </div>
        <span className="text-sm font-semibold tracking-tight">TaskSnap</span>
      </div>

      <nav className="flex flex-col gap-0.5">
        {items.map(({ to, label, icon: Icon }) => {
          const active = loc.pathname === to;
          return (
            <Link
              key={to}
              to={to}
              className={cn(
                "flex items-center gap-2.5 rounded-md px-2.5 py-1.5 text-sm transition-colors",
                active ? "bg-accent text-foreground" : "text-muted-foreground hover:bg-accent/50 hover:text-foreground"
              )}
            >
              <Icon className="h-4 w-4" />
              {label}
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto border-t border-border pt-3 px-1">
        <div className="text-xs text-muted-foreground truncate mb-2">{email}</div>
        <button
          onClick={() => supabase.auth.signOut()}
          className="flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground"
        >
          <LogOut className="h-3.5 w-3.5" /> Sign out
        </button>
      </div>
    </aside>
  );
}