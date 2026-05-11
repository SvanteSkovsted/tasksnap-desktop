import { Link, useLocation } from "@tanstack/react-router";
import { Inbox, CalendarDays, CheckCircle2, LogOut, Sparkles, ListChecks, Sun, Moon } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { cn } from "@/lib/utils";
import { useTheme } from "@/lib/theme";

const items = [
  { to: "/", label: "I dag", icon: Inbox },
  { to: "/upcoming", label: "Kommende", icon: CalendarDays },
  { to: "/all", label: "Alle opgaver", icon: ListChecks },
  { to: "/completed", label: "Færdige", icon: CheckCircle2 },
  { to: "/calendar", label: "Kalender", icon: CalendarDays },
] as const;

export function Sidebar({ email }: { email: string }) {
  const loc = useLocation();
  const { theme, toggle } = useTheme();
  return (
    <aside className="hidden md:flex w-60 flex-col border-r border-border/60 bg-surface/40 px-3 py-5 backdrop-blur-xl">
      <div className="px-2 mb-7 flex items-center gap-2.5">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/15 text-primary">
          <Sparkles className="h-4 w-4" />
        </div>
        <span className="text-[15px] font-semibold tracking-tight">TaskSnap</span>
      </div>

      <nav className="flex flex-col gap-0.5">
        {items.map(({ to, label, icon: Icon }) => {
          const active = loc.pathname === to;
          return (
            <Link
              key={to}
              to={to}
              className={cn(
                "flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-[13px] font-medium transition-all duration-200",
                active
                  ? "bg-card text-foreground shadow-[var(--shadow-warm)]"
                  : "text-muted-foreground hover:bg-accent/60 hover:text-foreground"
              )}
            >
              <Icon className="h-4 w-4" />
              {label}
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto border-t border-border/60 pt-3 px-1 space-y-2">
        <button
          onClick={toggle}
          className="flex w-full items-center gap-2 rounded-md px-1.5 py-1.5 text-xs text-muted-foreground hover:bg-accent/60 hover:text-foreground transition-colors"
        >
          {theme === "light" ? <Moon className="h-3.5 w-3.5" /> : <Sun className="h-3.5 w-3.5" />}
          {theme === "light" ? "Mørk tilstand" : "Lys tilstand"}
        </button>
        <div className="text-[11px] text-muted-foreground truncate px-1.5">{email}</div>
        <button
          onClick={() => supabase.auth.signOut()}
          className="flex items-center gap-2 px-1.5 text-[11px] text-muted-foreground hover:text-foreground transition-colors"
        >
          <LogOut className="h-3.5 w-3.5" /> Log ud
        </button>
      </div>
    </aside>
  );
}
