import { supabase } from "@/integrations/supabase/client";
import type { Task } from "@/lib/tasks";

const FIRED_KEY = "ts-fired-reminders";
const BRIEFING_KEY = "ts-briefing-date";

const getFired = (): Set<string> => {
  try {
    return new Set(JSON.parse(localStorage.getItem(FIRED_KEY) ?? "[]"));
  } catch { return new Set(); }
};
const saveFired = (s: Set<string>) => {
  const arr = [...s].slice(-200);
  localStorage.setItem(FIRED_KEY, JSON.stringify(arr));
};

export async function ensurePermission(): Promise<boolean> {
  if (typeof window === "undefined" || !("Notification" in window)) return false;
  if (Notification.permission === "granted") return true;
  if (Notification.permission === "denied") return false;
  const r = await Notification.requestPermission();
  return r === "granted";
}

const notify = (title: string, body?: string) => {
  if (typeof window === "undefined" || !("Notification" in window)) return;
  if (Notification.permission !== "granted") return;
  try { new Notification(title, { body, icon: "/favicon.svg" }); } catch {}
};

export function checkReminders(tasks: Task[]) {
  const now = Date.now();
  const fired = getFired();
  let changed = false;
  for (const t of tasks) {
    if (t.status === "done" || !t.due_date || !t.reminder_minutes) continue;
    const due = new Date(t.due_date).getTime();
    const fireAt = due - t.reminder_minutes * 60_000;
    const key = `${t.id}:${t.reminder_minutes}:${t.due_date}`;
    if (fired.has(key)) continue;
    if (fireAt <= now && now - fireAt < 6 * 60 * 60_000) {
      const minutesToDue = Math.max(0, Math.round((due - now) / 60_000));
      notify(`Påmindelse: ${t.title}`, minutesToDue > 0 ? `Forfalder om ${minutesToDue} min.` : `Forfalder nu.`);
      fired.add(key); changed = true;
    }
  }
  if (changed) saveFired(fired);
}

export function maybeMorningBriefing(tasks: Task[]) {
  const now = new Date();
  if (now.getHours() < 7) return;
  const today = now.toDateString();
  if (localStorage.getItem(BRIEFING_KEY) === today) return;
  const open = tasks.filter((t) => {
    if (t.status === "done" || !t.due_date) return false;
    const d = new Date(t.due_date);
    return d.toDateString() === today;
  });
  if (open.length === 0) {
    localStorage.setItem(BRIEFING_KEY, today);
    return;
  }
  notify("God morgen ☀️", `Du har ${open.length} opgave${open.length === 1 ? "" : "r"} i dag.`);
  localStorage.setItem(BRIEFING_KEY, today);
}

export async function getOnboardingStatus(userId: string): Promise<boolean> {
  const { data } = await supabase
    .from("user_settings")
    .select("onboarding_completed")
    .eq("user_id", userId)
    .maybeSingle();
  return Boolean(data?.onboarding_completed);
}

export async function completeOnboarding(userId: string) {
  await supabase
    .from("user_settings")
    .upsert({ user_id: userId, onboarding_completed: true }, { onConflict: "user_id" });
}
