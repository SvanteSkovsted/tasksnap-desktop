export const AUTH_KEYS = {
  TOKEN: "tasksnap_access_token",
  USER_ID: "tasksnap_user_id",
} as const;

export interface AuthData {
  token: string;
  userId: string;
}

export function getAuth(): AuthData | null {
  const token = localStorage.getItem(AUTH_KEYS.TOKEN);
  const userId = localStorage.getItem(AUTH_KEYS.USER_ID);
  if (token && userId) return { token, userId };
  return null;
}

export function clearAuth(): void {
  localStorage.removeItem(AUTH_KEYS.TOKEN);
  localStorage.removeItem(AUTH_KEYS.USER_ID);
}
