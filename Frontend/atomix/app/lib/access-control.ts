import { getInitialRoles, permissionsCatalog, normalizeRole, type RoleItem } from "~/components/roleActions";
import type { AuthUser } from "~/lib/auth";

const ROLE_SYSTEM_CACHE_KEY = "role-system-cache";

const moduleToPermissionIds: Record<string, string[]> = {
  HOME: ["page:dashboard"],
  SHIFT_REPORTS: ["page:reports"],
  TEMPLATES: ["page:templates", "page:template-editor"],
  ANALYTICS: ["page:analytics"],
  EMPLOYEES: ["page:employees", "page:employees-modal"],
  ORG_STRUCTURE: ["page:enterprise-structure"],
  ROLES: ["page:role-system"]
};

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

function normalizePath(pathname: string): string {
  if (!pathname) return "/";
  if (pathname === "/") return pathname;
  return pathname.replace(/\/+$/, "") || "/";
}

function getCachedRoles(): RoleItem[] {
  if (!isBrowser()) return [];

  try {
    const raw = window.localStorage.getItem(ROLE_SYSTEM_CACHE_KEY);
    if (!raw) return [];

    const parsed = JSON.parse(raw) as Array<Partial<RoleItem> & { id?: string | number; name: string }>;
    if (!Array.isArray(parsed)) return [];

    return parsed
      .filter((role) => role && typeof role === "object" && typeof role.name === "string")
      .map((role) => normalizeRole(role));
  } catch {
    return [];
  }
}

function resolveRoles(roles?: RoleItem[]): RoleItem[] {
  if (Array.isArray(roles) && roles.length > 0) return roles;

  const cachedRoles = getCachedRoles();
  if (cachedRoles.length > 0) return cachedRoles;

  return getInitialRoles();
}

export function getPermissionForPath(pathname: string) {
  const normalizedPath = normalizePath(pathname);

  if (normalizedPath === "/login") return null;

  return (
    permissionsCatalog.find((permission) => normalizePath(permission.path) === normalizedPath) ??
    permissionsCatalog.find((permission) => {
      const permissionPath = normalizePath(permission.path);
      if (permissionPath === "/") return normalizedPath === "/";
      return normalizedPath.startsWith(`${permissionPath}/`);
    }) ??
    null
  );
}

function getModulePermissionIds(moduleSlugs: string[] | undefined): string[] {
  if (!Array.isArray(moduleSlugs) || moduleSlugs.length === 0) return [];

  const permissionIds = new Set<string>();

  moduleSlugs.forEach((moduleSlug) => {
    const mappedPermissionIds = moduleToPermissionIds[moduleSlug] ?? [];
    mappedPermissionIds.forEach((permissionId) => permissionIds.add(permissionId));
  });

  return Array.from(permissionIds);
}

export function resolveAllowedPermissionIds(user: AuthUser | null, roles?: RoleItem[]): string[] {
  const allPermissionIds = permissionsCatalog.map((permission) => permission.id);
  if (!user) return [];

  const normalizedRoleName = user.roleName?.trim().toLowerCase();
  const userRoleId = String(user.roleId ?? "").trim();
  const availableRoles = resolveRoles(roles);
  const matchedRole = availableRoles.find((role) => {
    const roleId = String(role.backendRoleId ?? role.id).trim();
    const roleName = role.name.trim().toLowerCase();

    return Boolean(userRoleId && roleId === userRoleId) || Boolean(normalizedRoleName && roleName === normalizedRoleName);
  });

  if (matchedRole) {
    const normalizedPermissions = matchedRole.permissions.filter((permissionId) => allPermissionIds.includes(permissionId));
    if (matchedRole.permissionsConfigured) {
      return normalizedPermissions;
    }
    if (normalizedPermissions.length > 0) {
      return normalizedPermissions;
    }
  }

  const modulePermissionIds = getModulePermissionIds(user.modules);
  if (modulePermissionIds.length > 0) {
    return modulePermissionIds;
  }

  return allPermissionIds;
}

export function canAccessPath(pathname: string, user: AuthUser | null, roles?: RoleItem[]): boolean {
  const permission = getPermissionForPath(pathname);
  if (!permission) return true;

  return resolveAllowedPermissionIds(user, roles).includes(permission.id);
}

export function getFirstAllowedPath(user: AuthUser | null, roles?: RoleItem[]): string | null {
  const allowedPermissionIds = new Set(resolveAllowedPermissionIds(user, roles));
  const firstAllowedPermission = permissionsCatalog.find(
    (permission) => permission.includeInMenu && allowedPermissionIds.has(permission.id)
  );

  return firstAllowedPermission?.path ?? null;
}

export function getAllowedMenuPermissions(user: AuthUser | null, roles?: RoleItem[]) {
  const allowedPermissionIds = new Set(resolveAllowedPermissionIds(user, roles));
  return permissionsCatalog.filter(
    (permission) => permission.includeInMenu && allowedPermissionIds.has(permission.id)
  );
}
