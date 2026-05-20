export type PermissionItem = {
  id: string;
  label: string;
  path: string;
  moduleSlug?: string;
  icon?: string;
  includeInMenu?: boolean;
};

export type RoleItem = {
  id: string;
  name: string;
  participantIds: string[];
  permissions: string[];
  permissionsConfigured?: boolean;
  source?: "local" | "backend";
  backendRoleId?: string;
  description?: string;
  participantCount?: number;
  isActive?: boolean;
};

export const permissionsCatalog: PermissionItem[] = [
  {
    id: "page:dashboard",
    label: "Главная страница",
    path: "/",
    moduleSlug: "HOME",
    icon: "/icons/home.svg",
    includeInMenu: true
  },
  {
    id: "page:reports",
    label: "Рапорты",
    path: "/reports",
    moduleSlug: "SHIFT_REPORTS",
    icon: "/icons/paper.svg",
    includeInMenu: true
  },
  {
    id: "page:templates",
    label: "Шаблоны",
    path: "/templates",
    moduleSlug: "TEMPLATES",
    icon: "/icons/folder.svg",
    includeInMenu: true
  },
  {
    id: "page:template-editor",
    label: "Редактор шаблонов",
    path: "/templates/editor",
    moduleSlug: "TEMPLATES"
  },
  {
    id: "page:analytics",
    label: "Отчеты",
    path: "/analytics",
    moduleSlug: "ANALYTICS",
    icon: "/icons/clipboard.svg",
    includeInMenu: true
  },
  {
    id: "page:employees",
    label: "Сотрудники",
    path: "/employees",
    moduleSlug: "EMPLOYEES",
    icon: "/icons/employee.svg",
    includeInMenu: true
  },
  {
    id: "page:employees-modal",
    label: "Добавление сотрудника",
    path: "/employees-modal",
    moduleSlug: "EMPLOYEES"
  },
  {
    id: "page:enterprise-structure",
    label: "Структура предприятия",
    path: "/enterprise-structure",
    moduleSlug: "ORG_STRUCTURE",
    icon: "/icons/structure_folders.svg",
    includeInMenu: true
  },
  {
    id: "page:role-system",
    label: "Ролевая система",
    path: "/role-system",
    moduleSlug: "ROLES",
    icon: "/icons/role_system.svg",
    includeInMenu: true
  }
];

const legacyPermissionToPageIds: Record<string, string[]> = {
  fillShiftReport: ["page:dashboard"],
  reportsArchive: ["page:reports", "page:analytics"],
  reportsAccess: ["page:reports", "page:analytics"],
  templatesManage: ["page:templates", "page:template-editor"],
  rolesManage: ["page:role-system"],
  employeesManage: ["page:employees", "page:employees-modal", "page:enterprise-structure"]
};

const allPermissionIds = new Set(permissionsCatalog.map((permission) => permission.id));

function normalizeRoleId(value: unknown): string {
  const normalized = String(value ?? "").trim();
  if (normalized) return normalized;
  return `local-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
}

function normalizeParticipantIds(ids: unknown): string[] {
  if (!Array.isArray(ids)) return [];

  return Array.from(
    new Set(
      ids
        .map((id) => String(id ?? "").trim())
        .filter(Boolean)
    )
  );
}

export function normalizePermissions(permissions: unknown): string[] {
  if (!Array.isArray(permissions)) return [];

  const nextPermissions = new Set<string>();

  permissions.forEach((permission) => {
    const permissionId = String(permission ?? "").trim();
    if (!permissionId) return;

    if (allPermissionIds.has(permissionId)) {
      nextPermissions.add(permissionId);
      return;
    }

    const permissionByPath = permissionsCatalog.find((permission) => permission.path === permissionId);
    if (permissionByPath) {
      nextPermissions.add(permissionByPath.id);
      return;
    }

    const permissionByModule = permissionsCatalog.find((permission) => permission.moduleSlug === permissionId);
    if (permissionByModule) {
      permissionsCatalog
        .filter((permission) => permission.moduleSlug === permissionId)
        .forEach((permission) => nextPermissions.add(permission.id));
      return;
    }

    const mappedPermissionIds = legacyPermissionToPageIds[permissionId] ?? [];
    mappedPermissionIds.forEach((mappedPermissionId) => {
      if (allPermissionIds.has(mappedPermissionId)) {
        nextPermissions.add(mappedPermissionId);
      }
    });
  });

  return Array.from(nextPermissions);
}

export function mapModuleSlugsToPermissionIds(moduleSlugs: string[] | undefined): string[] {
  if (!Array.isArray(moduleSlugs) || moduleSlugs.length === 0) return [];

  const permissionIds = new Set<string>();

  moduleSlugs.forEach((moduleSlug) => {
    permissionsCatalog.forEach((permission) => {
      if (permission.moduleSlug === moduleSlug) {
        permissionIds.add(permission.id);
      }
    });
  });

  return Array.from(permissionIds);
}

export function getInitialRoles(): RoleItem[] {
  return [];
}

export function createRole(name: string, _roles: RoleItem[]): RoleItem {
  return {
    id: `local-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    name,
    participantIds: [],
    permissions: [],
    permissionsConfigured: true,
    source: "local"
  };
}

export function renameRole(roles: RoleItem[], roleId: string, nextName: string): RoleItem[] {
  return roles.map((role) => (role.id === roleId ? { ...role, name: nextName } : role));
}

export function getRoleParticipantsCount(role: RoleItem): number {
  if (typeof role.participantCount === "number" && Number.isFinite(role.participantCount)) {
    return role.participantCount;
  }
  return role.participantIds.length;
}

export function duplicateRole(roles: RoleItem[], roleId: string): RoleItem[] {
  const sourceRole = roles.find((role) => role.id === roleId);
  if (!sourceRole) return roles;

  const copyNameBase = `${sourceRole.name} (копия)`;
  const existingNames = new Set(roles.map((role) => role.name.trim().toLowerCase()));

  let copyName = copyNameBase;
  let copyIndex = 2;
  while (existingNames.has(copyName.trim().toLowerCase())) {
    copyName = `${copyNameBase} ${copyIndex}`;
    copyIndex += 1;
  }

  return [
    ...roles,
    {
      ...sourceRole,
      id: `local-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      name: copyName,
      participantIds: [],
      participantCount: 0,
      source: "local",
      backendRoleId: undefined
    }
  ];
}

export function togglePermission(roles: RoleItem[], roleId: string, permissionId: string): RoleItem[] {
  return roles.map((role) => {
    if (role.id !== roleId) return role;

    const nextPermissions = role.permissions.includes(permissionId)
      ? role.permissions.filter((id) => id !== permissionId)
      : [...role.permissions, permissionId];

    return {
      ...role,
      permissions: normalizePermissions(nextPermissions),
      permissionsConfigured: true
    };
  });
}

export function deleteRole(roles: RoleItem[], roleId: string): RoleItem[] {
  return roles.filter((role) => role.id !== roleId);
}

export function hydrateRolesWithParticipants<T extends { userId: string; roleId?: string; role?: string }>(
  roles: RoleItem[],
  employees: T[]
): RoleItem[] {
  return roles.map((role) => {
    const participantIds = employees
      .filter((employee) => {
        const employeeRoleId = String(employee.roleId ?? "").trim();
        const employeeRoleName = String(employee.role ?? "").trim().toLowerCase();
        const roleBackendId = String(role.backendRoleId ?? role.id).trim();
        const roleName = role.name.trim().toLowerCase();

        return (employeeRoleId && employeeRoleId === roleBackendId) || (employeeRoleName && employeeRoleName === roleName);
      })
      .map((employee) => employee.userId);

    return {
      ...role,
      participantIds: normalizeParticipantIds(participantIds),
      participantCount: participantIds.length
    };
  });
}

export function normalizeRole(input: Partial<RoleItem> & { id?: string | number; name: string }): RoleItem {
  return {
    id: normalizeRoleId(input.id),
    name: String(input.name ?? "").trim(),
    participantIds: normalizeParticipantIds(input.participantIds),
    permissions: normalizePermissions(input.permissions),
    permissionsConfigured: Boolean(input.permissionsConfigured),
    source: input.source === "backend" ? "backend" : "local",
    backendRoleId: typeof input.backendRoleId === "string" ? input.backendRoleId : undefined,
    description: typeof input.description === "string" ? input.description : undefined,
    participantCount:
      typeof input.participantCount === "number" && Number.isFinite(input.participantCount)
        ? input.participantCount
        : undefined,
    isActive: typeof input.isActive === "boolean" ? input.isActive : undefined
  };
}
