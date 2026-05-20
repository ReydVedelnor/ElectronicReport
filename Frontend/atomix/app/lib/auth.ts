export type AuthUser = {
  userId: string;
  login: string;
  fullName: string;
  roleId?: string;
  roleName?: string;
  modules?: string[];
};

export const AUTH_STORAGE_KEY = "atomix-auth-user";
export const AUTH_EVENT_NAME = "atomix-auth-changed";
export const SHIFT_SESSION_KEY = "dashboard-shift-started";

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

export function getApiBaseUrl(): string {
  const envUrl = import.meta.env.VITE_API_URL?.trim();
  return envUrl && envUrl.length > 0 ? envUrl : "http://localhost:8080";
}

export function getStoredAuthUser(): AuthUser | null {
  if (!isBrowser()) return null;

  try {
    const raw = window.localStorage.getItem(AUTH_STORAGE_KEY);
    if (!raw) return null;

    const parsed = JSON.parse(raw) as Partial<AuthUser>;
    if (!parsed || typeof parsed !== "object") return null;
    if (!parsed.userId || !parsed.login) return null;

    return {
      userId: parsed.userId,
      login: parsed.login,
      fullName: parsed.fullName?.trim() || parsed.login,
      roleId: typeof parsed.roleId === "string" ? parsed.roleId : undefined,
      roleName: typeof parsed.roleName === "string" ? parsed.roleName : undefined,
      modules: Array.isArray(parsed.modules)
        ? parsed.modules.map((moduleSlug) => String(moduleSlug ?? "").trim()).filter(Boolean)
        : undefined
    };
  } catch {
    return null;
  }
}

export function saveAuthUser(user: AuthUser): void {
  if (!isBrowser()) return;

  window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(user));
  notifyAuthChanged();
}

export function clearAuthSession(): void {
  if (!isBrowser()) return;

  window.localStorage.removeItem(AUTH_STORAGE_KEY);
  window.sessionStorage.removeItem(SHIFT_SESSION_KEY);
  notifyAuthChanged();
}

export function notifyAuthChanged(): void {
  if (!isBrowser()) return;
  window.dispatchEvent(new Event(AUTH_EVENT_NAME));
}
