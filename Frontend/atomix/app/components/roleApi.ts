import {
  createRole,
  hydrateRolesWithParticipants,
  mapModuleSlugsToPermissionIds,
  normalizePermissions,
  permissionsCatalog,
  type RoleItem
} from "./roleActions";
import { getApiBaseUrl, notifyAuthChanged } from "../lib/auth";

export type BackendRoleItem = {
  id?: string;
  roleId?: string;
  name?: string;
  roleName?: string;
  title?: string;
  description?: string;
  permissions?: unknown[];
  permissionIds?: unknown[];
  pages?: unknown[];
  pagePermissions?: unknown[];
  modules?: unknown[];
  moduleSlugs?: unknown[];
  participants?: unknown[];
  users?: unknown[];
  employees?: unknown[];
  participantIds?: unknown[];
  userIds?: unknown[];
  employeeIds?: unknown[];
  participantCount?: number;
  participantsCount?: number;
  membersCount?: number;
  usersCount?: number;
  isActive?: boolean;
  active?: boolean;
};

export type BackendEmployeeItem = {
  userId?: string;
  id?: string;
  employeeId?: string;
  fullName?: string;
  name?: string;
  login?: string;
  username?: string;
  roleId?: string | null;
  roleName?: string | null;
  departmentId?: string;
  departmentName?: string;
  office?: string;
  isActive?: boolean;
  active?: boolean;
};

type BackendModuleItem = {
  moduleId?: string;
  id?: string;
  slug?: string;
  moduleSlug?: string;
  isActive?: boolean;
  active?: boolean;
};

type BackendListResponse<T> = {
  items?: T[];
  modules?: T[];
  roles?: T[];
  data?: T[];
  content?: T[];
  users?: T[];
  employees?: T[];
  participants?: T[];
};

export type EmployeeRecord = {
  userId: string;
  name: string;
  login: string;
  role: string;
  roleId: string;
  office: string;
  departmentId: string;
  isActive: boolean;
};

type RequestOptions = RequestInit & {
  allowNotFound?: boolean;
};

export const ROLE_SYSTEM_CACHE_KEY = "role-system-cache";

export function normalizeRoleName(value: string | undefined | null): string {
  return String(value ?? "").trim().toLowerCase();
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === "object" && !Array.isArray(value);
}

function asArray<T>(payload: unknown, keys: Array<keyof BackendListResponse<T>>): T[] {
  if (Array.isArray(payload)) return payload as T[];
  if (!isRecord(payload)) return [];

  for (const key of keys) {
    const value = payload[key as string];
    if (Array.isArray(value)) return value as T[];
  }

  return [];
}

export function extractId(value: unknown): string {
  if (isRecord(value)) {
    return String(value.id ?? value.roleId ?? value.userId ?? value.employeeId ?? "").trim();
  }
  return String(value ?? "").trim();
}

function extractPermissionIds(role: BackendRoleItem): string[] {
  const directPermissions = [
    ...(Array.isArray(role.permissions) ? role.permissions : []),
    ...(Array.isArray(role.permissionIds) ? role.permissionIds : []),
    ...(Array.isArray(role.pages) ? role.pages : []),
    ...(Array.isArray(role.pagePermissions) ? role.pagePermissions : [])
  ].map((permission) => {
    if (isRecord(permission)) {
      return String(
        permission.id ??
          permission.permissionId ??
          permission.code ??
          permission.slug ??
          permission.pageId ??
          permission.path ??
          ""
      ).trim();
    }
    return String(permission ?? "").trim();
  });

  const moduleSlugs = [
    ...(Array.isArray(role.modules) ? role.modules : []),
    ...(Array.isArray(role.moduleSlugs) ? role.moduleSlugs : [])
  ].flatMap((moduleItem) => {
    if (isRecord(moduleItem)) {
      const enabled = typeof moduleItem.isEnabled === "boolean" ? moduleItem.isEnabled : true;
      if (!enabled) return [];
      return String(moduleItem.slug ?? moduleItem.moduleSlug ?? moduleItem.code ?? moduleItem.name ?? "").trim();
    }
    return String(moduleItem ?? "").trim();
  });

  return normalizePermissions([...directPermissions, ...mapModuleSlugsToPermissionIds(moduleSlugs)]);
}

function extractParticipantIds(role: BackendRoleItem): string[] {
  const values = [
    ...(Array.isArray(role.participantIds) ? role.participantIds : []),
    ...(Array.isArray(role.userIds) ? role.userIds : []),
    ...(Array.isArray(role.employeeIds) ? role.employeeIds : []),
    ...(Array.isArray(role.participants) ? role.participants : []),
    ...(Array.isArray(role.users) ? role.users : []),
    ...(Array.isArray(role.employees) ? role.employees : [])
  ];

  return Array.from(new Set(values.map(extractId).filter(Boolean)));
}

export function backendRoleToItem(role: BackendRoleItem): RoleItem | null {
  const roleId = String(role.roleId ?? role.id ?? "").trim();
  const roleName = String(role.name ?? role.roleName ?? role.title ?? "").trim();
  if (!roleId || !roleName) return null;

  const participantIds = extractParticipantIds(role);
  const participantCount =
    typeof role.participantsCount === "number"
      ? role.participantsCount
      : typeof role.participantCount === "number"
        ? role.participantCount
        : typeof role.membersCount === "number"
          ? role.membersCount
          : typeof role.usersCount === "number"
            ? role.usersCount
            : participantIds.length;

  return {
    id: roleId,
    name: roleName,
    participantIds,
    participantCount,
    permissions: extractPermissionIds(role),
    permissionsConfigured: true,
    source: "backend",
    backendRoleId: roleId,
    description: String(role.description ?? "").trim() || undefined,
    isActive: typeof role.isActive === "boolean" ? role.isActive : role.active !== false
  };
}

export function backendEmployeeToRecord(item: BackendEmployeeItem): EmployeeRecord {
  return {
    userId: String(item.userId ?? item.id ?? item.employeeId ?? "").trim(),
    name: String(item.fullName ?? item.name ?? "").trim(),
    login: String(item.login ?? item.username ?? "").trim(),
    role: String(item.roleName ?? "").trim(),
    roleId: String(item.roleId ?? "").trim(),
    office: String(item.departmentName ?? item.office ?? "").trim(),
    departmentId: String(item.departmentId ?? "").trim(),
    isActive: typeof item.isActive === "boolean" ? item.isActive : item.active !== false
  };
}

function getModuleSlugsByPermissions(permissions: string[]): string[] {
  return Array.from(
    new Set(
      permissions
        .map((permissionId) => permissionsCatalog.find((permission) => permission.id === permissionId)?.moduleSlug)
        .filter(Boolean) as string[]
    )
  );
}

export async function requestJson<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { allowNotFound, headers, ...requestOptions } = options;
  const response = await fetch(`${getApiBaseUrl()}${path}`, {
    ...requestOptions,
    headers: {
      ...(requestOptions.body ? { "Content-Type": "application/json" } : {}),
      ...headers
    }
  });

  if (allowNotFound && response.status === 404) {
    throw new Error("NOT_FOUND");
  }

  let payload: unknown = null;
  const text = await response.text();
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch {
      payload = text;
    }
  }

  if (!response.ok) {
    const backendMessage = isRecord(payload) && typeof payload.message === "string" ? payload.message : "";
    throw new Error(backendMessage || `Ошибка запроса ${response.status}`);
  }

  return payload as T;
}

export async function tryRequests<T>(requests: Array<() => Promise<T>>): Promise<T> {
  let lastError: unknown;

  for (const request of requests) {
    try {
      return await request();
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError instanceof Error ? lastError : new Error("Не удалось выполнить запрос.");
}

function isModuleActive(moduleItem: BackendModuleItem): boolean {
  return moduleItem.isActive !== false && moduleItem.active !== false;
}

async function fetchRoleCreateContextModules(): Promise<BackendModuleItem[]> {
  const payload = await requestJson<unknown>(`/api/roles/create-context`);

  return asArray<BackendModuleItem>(payload, [
    "modules",
    "items",
    "data",
    "content"
  ]).filter(isModuleActive);
}

export async function fetchActivePermissionIdsFromApi(): Promise<string[]> {
  const modules = await fetchRoleCreateContextModules();
  const moduleSlugs = modules
    .map((moduleItem) => String(moduleItem.slug ?? moduleItem.moduleSlug ?? "").trim())
    .filter(Boolean);

  return mapModuleSlugsToPermissionIds(moduleSlugs);
}

async function fetchModuleIdsBySlug(): Promise<Record<string, string>> {
  const modules = await fetchRoleCreateContextModules();

  return modules.reduce<Record<string, string>>((acc, moduleItem) => {
    const slug = String(moduleItem.slug ?? moduleItem.moduleSlug ?? "").trim();
    const moduleId = String(moduleItem.moduleId ?? moduleItem.id ?? "").trim();
    if (slug && moduleId) {
      acc[slug] = moduleId;
    }
    return acc;
  }, {});
}

async function buildRolePayload(
  role: Pick<RoleItem, "name" | "permissions" | "description" | "isActive">
): Promise<{ name: string; description: string; isActive?: boolean; moduleIds: string[] }> {
  const moduleIdsBySlug = await fetchModuleIdsBySlug();
  const moduleIds = getModuleSlugsByPermissions(role.permissions)
    .map((moduleSlug) => moduleIdsBySlug[moduleSlug])
    .filter(Boolean);

  return {
    name: role.name.trim(),
    description: role.description ?? "",
    ...(typeof role.isActive === "boolean" ? { isActive: role.isActive } : {}),
    moduleIds: Array.from(new Set(moduleIds))
  };
}

export function hasPermissionChanges(previousRole: RoleItem, nextRole: RoleItem): boolean {
  const previous = [...previousRole.permissions].sort().join("|");
  const next = [...nextRole.permissions].sort().join("|");
  return previous !== next;
}

export async function fetchRolesFromApi(userId: string): Promise<RoleItem[]> {
  const payload = await tryRequests<unknown>([
    () => requestJson(`/api/roles?userId=${encodeURIComponent(userId)}&page=0&size=1000&activity=all`),
    () => requestJson(`/api/roles?page=0&size=1000&activity=all`),
    () => requestJson(`/api/roles`)
  ]);

  const listRoles = asArray<BackendRoleItem>(payload, ["items", "roles", "data", "content"])
    .map(backendRoleToItem)
    .filter((role): role is RoleItem => Boolean(role));

  const detailedRoles = await Promise.all(
    listRoles.map(async (role) => {
      const roleId = role.backendRoleId ?? role.id;
      try {
        const details = await requestJson<unknown>(`/api/roles/${encodeURIComponent(roleId)}`);
        const detailedRole = backendRoleToItem(details as BackendRoleItem);

        if (!detailedRole) {
          return role;
        }

        return {
          ...detailedRole,
          isActive: role.isActive === false ? false : detailedRole.isActive
        };
      } catch {
        return role;
      }
    })
  );

  return detailedRoles;
}

export async function fetchRoleFromApi(roleId: string): Promise<RoleItem> {
  const payload = await requestJson<unknown>(`/api/roles/${encodeURIComponent(roleId)}`);
  const role = backendRoleToItem(payload as BackendRoleItem);
  if (!role) {
    throw new Error("Не удалось загрузить карточку роли.");
  }
  return role;
}

export async function fetchEmployeesFromApi(userId: string): Promise<EmployeeRecord[]> {
  const payload = await requestJson<unknown>(
    `/api/employees?userId=${encodeURIComponent(userId)}&page=0&size=1000&activity=true`
  );

  return asArray<BackendEmployeeItem>(payload, ["items", "employees", "users", "data", "content"])
    .map(backendEmployeeToRecord)
    .filter((employee) => employee.userId && employee.name);
}

export async function createRoleOnApi(
  name: string,
  permissions: string[] = [],
  description = ""
): Promise<RoleItem> {
  const localRole = { ...createRole(name, []), permissions: normalizePermissions(permissions), description };
  const payload = await buildRolePayload(localRole);
  const response = await requestJson<unknown>(`/api/roles/create`, {
    method: "POST",
    body: JSON.stringify(payload)
  });

  return backendRoleToItem(response as BackendRoleItem) ?? {
    ...localRole,
    id: extractId(response) || localRole.id,
    backendRoleId: extractId(response) || localRole.id,
    source: "backend",
    permissionsConfigured: true
  };
}

export async function updateRoleOnApi(roleId: string, role: RoleItem): Promise<RoleItem> {
  const payload = await buildRolePayload(role);
  const response = await requestJson<unknown>(`/api/roles/${encodeURIComponent(roleId)}`, {
    method: "PATCH",
    body: JSON.stringify(payload)
  });

  return backendRoleToItem(response as BackendRoleItem) ?? {
    ...role,
    id: roleId,
    backendRoleId: roleId,
    source: "backend",
    permissionsConfigured: true
  };
}

export async function activateRoleOnApi(roleId: string): Promise<void> {
  await requestJson<unknown>(`/api/roles/${encodeURIComponent(roleId)}`, {
    method: "PATCH",
    body: JSON.stringify({ isActive: true })
  });
}

export async function deactivateRoleOnApi(roleId: string): Promise<void> {
  await requestJson<unknown>(`/api/roles/${encodeURIComponent(roleId)}`, {
    method: "PATCH",
    body: JSON.stringify({ isActive: false })
  });
}

export async function assignEmployeeRoleOnApi(employeeId: string, roleId: string, userId: string): Promise<void> {
  await requestJson<void>(`/api/employees/${encodeURIComponent(employeeId)}`, {
    method: "PATCH",
    body: JSON.stringify({ updatedByUserId: userId, roleId })
  });
}

export async function removeEmployeeRoleOnApi(employeeId: string, roleId: string, userId: string): Promise<void> {
  await tryRequests<void>([
    () =>
      requestJson<void>(`/api/roles/${encodeURIComponent(roleId)}/participants/${encodeURIComponent(employeeId)}`, {
        method: "DELETE"
      }),
    () =>
      requestJson<void>(`/api/roles/${encodeURIComponent(roleId)}/users/${encodeURIComponent(employeeId)}`, {
        method: "DELETE"
      }),
    () =>
      requestJson<void>(`/api/employees/${encodeURIComponent(employeeId)}`, {
        method: "PATCH",
        body: JSON.stringify({ updatedByUserId: userId, roleId: null })
      })
  ]);
}

export function hydrateRoles(roles: RoleItem[], employees: EmployeeRecord[]): RoleItem[] {
  return hydrateRolesWithParticipants(roles, employees);
}

export function saveRolesCache(roles: RoleItem[]) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(ROLE_SYSTEM_CACHE_KEY, JSON.stringify(roles));
  notifyAuthChanged();
}

export function updateRoleInCache(roleId: string, patch: Partial<RoleItem>) {
  if (typeof window === "undefined") return;

  try {
    const rawRoles = window.localStorage.getItem(ROLE_SYSTEM_CACHE_KEY);
    const cachedRoles = rawRoles ? (JSON.parse(rawRoles) as RoleItem[]) : [];
    if (!Array.isArray(cachedRoles) || cachedRoles.length === 0) return;

    const nextRoles = cachedRoles.map((role) =>
      (role.backendRoleId ?? role.id) === roleId ? { ...role, ...patch } : role
    );

    saveRolesCache(nextRoles);
  } catch {
    // Если локальный cache поврежден, не блокируем основное действие с ролью.
  }
}
