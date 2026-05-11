import type { Database } from "@/integrations/supabase/types";

export type Task = {
  id: string;
  user_id: string;
  title: string;
  description: string | null;
  priority: "urgent" | "high" | "medium" | "low";
  status: "todo" | "in_progress" | "done";
  category: string | null;
  due_date: string | null;
  completed_at: string | null;
  source: string | null;
  created_at: string;
  updated_at: string;
};

export const PRIORITY_ORDER: Record<Task["priority"], number> = {
  urgent: 0, high: 1, medium: 2, low: 3,
};

export const priorityClass = (p: Task["priority"]) => {
  switch (p) {
    case "urgent": return "text-priority-urgent border-priority-urgent/40 bg-priority-urgent/10";
    case "high": return "text-priority-high border-priority-high/40 bg-priority-high/10";
    case "medium": return "text-priority-medium border-priority-medium/40 bg-priority-medium/10";
    case "low": return "text-priority-low border-priority-low/40 bg-priority-low/10";
  }
};

export const priorityDot = (p: Task["priority"]) => {
  switch (p) {
    case "urgent": return "bg-priority-urgent";
    case "high": return "bg-priority-high";
    case "medium": return "bg-priority-medium";
    case "low": return "bg-priority-low";
  }
};

// keep for type import
export type _DB = Database;