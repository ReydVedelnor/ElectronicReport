import React, { useEffect, useMemo, useState } from "react";
import { AppModal } from "~/components/app-modal";
import { useLocation, useNavigate, useParams } from "react-router";
import { SvgIcon } from "~/components/svg-icon";
import {
  createRole,
  hydrateRolesWithParticipants,
  mapModuleSlugsToPermissionIds,
  permissionsCatalog,
  togglePermission,
  type PermissionItem,
  type RoleItem
} from "../components/roleActions";
import {
  createRoleOnApi,
  fetchActivePermissionIdsFromApi,
  fetchEmployeesFromApi,
  fetchRoleFromApi,
  hasPermissionChanges,
  normalizeRoleName,
  updateRoleOnApi,
  type EmployeeRecord
} from "../components/roleApi";
import { getStoredAuthUser } from "../lib/auth";

type ToastState = {
  message: string;
  type: "success" | "info";
};

type PendingExit = {
  path: string;
  state?: unknown;
};

type SaveRoleOptions = {
  exitAfterSave?: boolean;
};

function createEmptyDraftRole(): RoleItem {
  return {
    ...createRole("", []),
    id: "new-role-draft",
    name: "",
    permissions: [],
    participantIds: [],
    participantCount: 0,
    permissionsConfigured: true,
    source: "local",
    backendRoleId: undefined
  };
}

function cloneRole(role: RoleItem): RoleItem {
  return {
    ...role,
    permissions: [...role.permissions],
    participantIds: [...role.participantIds]
  };
}

function filterRolePermissionsByAvailable(role: RoleItem, availablePermissionIds: Set<string>): RoleItem {
  return {
    ...role,
    permissions: role.permissions.filter((permissionId) => availablePermissionIds.has(permissionId))
  };
}

function getRoleKey(role: RoleItem): string {
  return role.backendRoleId ?? role.id;
}

function isEmployeeAssignedToRole(employee: EmployeeRecord, role: RoleItem): boolean {
  const roleName = normalizeRoleName(role.name);

  return (
    employee.roleId === getRoleKey(role) ||
    (Boolean(roleName) && normalizeRoleName(employee.role) === roleName)
  );
}

function splitEmployeeName(fullName: string) {
  const [lastName = "", firstName = "", middleName = ""] = String(fullName || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  return { lastName, firstName, middleName };
}

function employeeRecordToNavigationState(employee: EmployeeRecord) {
  const parts = splitEmployeeName(employee.name);

  return {
    employee: {
      id: 0,
      userId: employee.userId,
      name: employee.name,
      fullName: employee.name,
      login: employee.login,
      position: employee.role,
      role: employee.role,
      roleId: employee.roleId,
      office: employee.office,
      department: employee.office,
      departmentId: employee.departmentId,
      isActive: employee.isActive,
      lastName: parts.lastName,
      firstName: parts.firstName,
      middleName: parts.middleName,
      source: "api"
    }
  };
}

export default function RoleSystemEditorPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { roleId: routeRoleId } = useParams();
  const searchParams = new URLSearchParams(location.search);
  const queryRoleId = searchParams.get("roleId") || undefined;
  const roleId = routeRoleId ?? queryRoleId;
  const authUser = useMemo(() => getStoredAuthUser(), []);
  const isCreateMode = location.pathname.endsWith("/new") || searchParams.get("mode") === "new" || !roleId;

  const [sourceRole, setSourceRole] = useState<RoleItem | null>(null);
  const [draftRole, setDraftRole] = useState<RoleItem | null>(isCreateMode ? createEmptyDraftRole() : null);
  const [availablePermissions, setAvailablePermissions] = useState<PermissionItem[]>(permissionsCatalog);
  const [employees, setEmployees] = useState<EmployeeRecord[]>([]);
  const [toast, setToast] = useState<ToastState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSavingRole, setIsSavingRole] = useState(false);
  const [showUnsavedExitModal, setShowUnsavedExitModal] = useState(false);
  const [pendingExit, setPendingExit] = useState<PendingExit | null>(null);
  const [errorMessage, setErrorMessage] = useState("");

  const currentRolePermissions = useMemo(
    () => mapModuleSlugsToPermissionIds(authUser?.modules),
    [authUser?.modules]
  );

  const showToast = (message: string, type: ToastState["type"] = "success") => {
    setToast({ message, type });
  };

  const loadData = async () => {
    if (!authUser?.userId) {
      setSourceRole(null);
      setDraftRole(null);
      setEmployees([]);
      setErrorMessage("Не удалось определить текущего пользователя.");
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setErrorMessage("");

      const [apiEmployees, apiRole, activePermissionIds] = await Promise.all([
        fetchEmployeesFromApi(authUser.userId),
        isCreateMode || !roleId ? Promise.resolve(null) : fetchRoleFromApi(roleId),
        fetchActivePermissionIdsFromApi()
      ]);

      const activePermissionIdSet = new Set(activePermissionIds);
      const nextAvailablePermissions = permissionsCatalog.filter((permission) =>
        activePermissionIdSet.has(permission.id)
      );
      const activeCurrentRolePermissions = currentRolePermissions.filter((permissionId) =>
        activePermissionIdSet.has(permissionId)
      );

      const preparedRole = apiRole
        ? hydrateRolesWithParticipants([
            apiRole.permissions.length > 0 || activeCurrentRolePermissions.length === 0
              ? apiRole
              : {
                  ...apiRole,
                  permissions: activeCurrentRolePermissions,
                  permissionsConfigured: true
                }
          ], apiEmployees)[0]
        : hydrateRolesWithParticipants([createEmptyDraftRole()], apiEmployees)[0];

      const preparedRoleWithOnlyActivePermissions = filterRolePermissionsByAvailable(
        preparedRole,
        activePermissionIdSet
      );

      setAvailablePermissions(nextAvailablePermissions);
      setEmployees(apiEmployees);
      setSourceRole(apiRole ? cloneRole(preparedRoleWithOnlyActivePermissions) : null);
      setDraftRole(cloneRole(preparedRoleWithOnlyActivePermissions));
    } catch (error) {
      console.error("Ошибка загрузки роли:", error);
      setSourceRole(null);
      setDraftRole(null);
      setEmployees([]);
      setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить роль");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [authUser?.userId, roleId, isCreateMode, currentRolePermissions]);

  useEffect(() => {
    if (!toast) return undefined;
    const timeoutId = window.setTimeout(() => setToast(null), 2600);
    return () => window.clearTimeout(timeoutId);
  }, [toast]);

  const roleParticipants = useMemo(() => {
    if (isCreateMode || !sourceRole) return [];

    return employees
      .filter(
        (employee) =>
          sourceRole.participantIds.includes(employee.userId) ||
          isEmployeeAssignedToRole(employee, sourceRole)
      )
      .sort((left, right) => left.name.localeCompare(right.name, "ru"));
  }, [employees, isCreateMode, sourceRole]);

  const hasUnsavedChanges = useMemo(() => {
    if (!draftRole) return false;

    if (isCreateMode) {
      return Boolean(draftRole.name.trim()) || draftRole.permissions.length > 0;
    }

    if (!sourceRole) return false;

    const roleNameChanged = sourceRole.name !== draftRole.name;
    const permissionsChanged = hasPermissionChanges(sourceRole, draftRole);

    return roleNameChanged || permissionsChanged;
  }, [draftRole, isCreateMode, sourceRole]);

  const navigateToExitTarget = (exitTarget: PendingExit | null = pendingExit) => {
    const target = exitTarget ?? { path: "/role-system" };
    navigate(target.path, target.state ? { state: target.state } : undefined);
  };

  const requestExit = (exitTarget: PendingExit) => {
    if (hasUnsavedChanges) {
      setPendingExit(exitTarget);
      setShowUnsavedExitModal(true);
      return;
    }

    navigateToExitTarget(exitTarget);
  };

  const handleBackClick = () => {
    requestExit({ path: "/role-system" });
  };

  const handleOpenEmployeeCard = (employee: EmployeeRecord) => {
    requestExit({
      path: `/employees/edit/${encodeURIComponent(employee.userId)}`,
      state: employeeRecordToNavigationState(employee)
    });
  };

  const handleExitWithoutSaving = () => {
    setShowUnsavedExitModal(false);
    const exitTarget = pendingExit;
    setPendingExit(null);
    navigateToExitTarget(exitTarget);
  };

  const handleRenameRole = () => {
    if (!draftRole) return;

    const nextName = window.prompt(
      isCreateMode ? "Введите название новой роли:" : "Название роли:",
      draftRole.name
    );
    if (nextName === null) return;

    const trimmedName = nextName.trim();
    if (!trimmedName) {
      window.alert("Название роли не может быть пустым.");
      return;
    }

    setDraftRole((prev) => (prev ? { ...prev, name: trimmedName } : prev));
  };


  const handleTogglePermission = (permissionId: string) => {
    setDraftRole((prev) => {
      if (!prev) return prev;
      return togglePermission([prev], prev.id, permissionId)[0];
    });
  };

  const saveNewRole = async (exitAfterSave = false) => {
    if (!draftRole || !authUser?.userId) return false;

    const roleName = draftRole.name.trim();
    if (!roleName) {
      window.alert("Перед сохранением укажите название роли.");
      return false;
    }

    const createdRole = await createRoleOnApi(roleName, draftRole.permissions, draftRole.description ?? "");
    const createdRoleId = getRoleKey(createdRole);

    showToast("Роль создана.");
    if (exitAfterSave) {
      navigateToExitTarget();
    } else {
      navigate(`/role-system?roleId=${encodeURIComponent(createdRoleId)}`);
    }
    return true;
  };

  const saveExistingRole = async (exitAfterSave = false) => {
    if (!sourceRole || !draftRole || !authUser?.userId) return false;

    const roleName = draftRole.name.trim();
    if (!roleName) {
      window.alert("Перед сохранением укажите название роли.");
      return false;
    }

    const nextRoleId = getRoleKey(draftRole);
    const roleFromApi = await updateRoleOnApi(nextRoleId, {
      ...draftRole,
      name: roleName,
      isActive: draftRole.isActive ?? true
    });

    const savedRole = {
      ...draftRole,
      ...roleFromApi,
      participantIds: sourceRole.participantIds,
      participantCount: sourceRole.participantCount
    };

    setSourceRole(cloneRole(savedRole));
    setDraftRole(cloneRole(savedRole));

    showToast("Изменения роли сохранены.");

    if (exitAfterSave) {
      navigateToExitTarget();
    }

    return true;
  };

  const handleSaveRole = async ({ exitAfterSave = false }: SaveRoleOptions = {}) => {
    try {
      setIsSavingRole(true);
      const isSaved = isCreateMode
        ? await saveNewRole(exitAfterSave)
        : await saveExistingRole(exitAfterSave);

      if (exitAfterSave && isSaved) {
        setShowUnsavedExitModal(false);
        setPendingExit(null);
      }
    } catch (error) {
      console.error("Ошибка сохранения роли:", error);
      showToast(error instanceof Error ? error.message : "Не удалось сохранить изменения роли.", "info");
    } finally {
      setIsSavingRole(false);
    }
  };

  if (isLoading) {
    return (
      <div className="role-system-page">
        <section className="ui-card role-system-card role-system-card--list">
          <div className="ui-empty">Загрузка роли...</div>
        </section>
      </div>
    );
  }

  if (errorMessage || !draftRole) {
    return (
      <div className="role-system-page">
        <div className="role-system-header">
          <div className="role-system-header__left">
            <button type="button" className="role-system-back" onClick={() => navigate("/role-system")} title="Назад">
              <SvgIcon name="back" />
            </button>
            <div className="role-system-title-wrap">
              <h1 className="role-system-title">Роль не найдена</h1>
            </div>
          </div>
        </div>
        <section className="ui-card role-system-card role-system-card--list">
          <div className="ui-empty">{errorMessage || "Не удалось открыть роль."}</div>
        </section>
      </div>
    );
  }

  return (
    <div className="role-system-page">
      <div className="role-system-header">
        <div className="role-system-header__left">
          <button
            type="button"
            className="role-system-back"
            onClick={handleBackClick}
            title="Назад"
          >
            <SvgIcon name="back" />
          </button>

          <div className="role-system-title-wrap">
            <h1 className="role-system-title">{draftRole.name || "Новая роль"}</h1>
            <button
              type="button"
              className="role-system-title-edit"
              onClick={handleRenameRole}
              title="Переименовать роль"
            >
              <SvgIcon name="edit" />
            </button>
          </div>
        </div>

        <div className="role-system-header__actions">
          <button
            type="button"
            className="role-system-header-btn role-system-header-btn--save"
            onClick={() => handleSaveRole()}
            disabled={isSavingRole}
          >
            <SvgIcon name="save" />
            <span>{isSavingRole ? "Сохранение..." : "Сохранить"}</span>
          </button>

          
        </div>
      </div>

      <div className="role-system-detail-grid">
        <section className="role-system-card role-system-card--permissions">
          <div className="role-system-card-head">
            <div>
              <h2 className="role-system-card-title">Права доступа по страницам</h2>
              <p className="role-system-card-subtitle">
                Для каждой страницы системы можно включить доступ отдельно.
              </p>
            </div>
          </div>

          <div className="role-system-table-wrap">
            <table className="role-system-table role-system-table--permissions">
              <tbody>
                {availablePermissions.length > 0 ? (
                  availablePermissions.map((permission) => {
                    const isActive = draftRole.permissions.includes(permission.id);

                    return (
                      <tr key={permission.id}>
                        <td className="role-system-table__text-cell">
                          <div className="role-system-permission-cell">
                            <div className="role-system-permission-cell__title">{permission.label}</div>
                          </div>
                        </td>
                        <td className="role-system-table__action-cell">
                          <button
                            type="button"
                            className={`role-system-check ${isActive ? "is-active" : ""}`}
                            onClick={() => handleTogglePermission(permission.id)}
                            title={isActive ? "Отключить доступ" : "Включить доступ"}
                          >
                            <SvgIcon name="check" />
                          </button>
                        </td>
                      </tr>
                    );
                  })
                ) : (
                  <tr>
                    <td className="role-system-table__text-cell" colSpan={2}>
                      <div className="role-system-empty-note">Нет активных страниц для настройки прав.</div>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </section>

        <section className="role-system-card role-system-card--members">
          <div className="role-system-card-head role-system-card-head--members">
            <div>
              <div className="role-system-card-title-row">
                <h2 className="role-system-card-title">Участники роли</h2>
                {isCreateMode ? <span className="role-system-disabled-badge">Новая роль</span> : null}
              </div>
              <div className="role-system-members-count">
                <SvgIcon name="users" />
                <span>{roleParticipants.length}</span>
              </div>
              <p className="role-system-card-subtitle">
                Здесь показаны текущие участники роли. Изменить роль сотрудника можно в его карточке на вкладке «Сотрудники».
              </p>
            </div>
          </div>

          <div className="role-system-members-list">
            {roleParticipants.length > 0 ? (
              roleParticipants.map((employee) => (
                <button
                  key={employee.userId}
                  type="button"
                  className="role-system-member role-system-member--readonly role-system-member--link"
                  onClick={() => handleOpenEmployeeCard(employee)}
                  title="Открыть карточку сотрудника"
                >
                  <div className="role-system-member__info">
                    <div className="role-system-member__name">{employee.name}</div>
                    <div className="role-system-member__meta">
                      {employee.login ? `${employee.login} • ` : ""}
                      {employee.office || "Без подразделения"}
                      {employee.role ? ` • Текущая роль: ${employee.role}` : ""}
                    </div>
                  </div>

                  <span className="role-system-member__view-icon" title="Открыть карточку сотрудника">
                    <SvgIcon name="edit" />
                  </span>
                </button>
              ))
            ) : (
              <div className="role-system-empty-note">
                {isCreateMode
                  ? "У новой роли пока нет участников."
                  : "У этой роли пока нет участников."}
              </div>
            )}
          </div>
        </section>
      </div>

      <AppModal
        open={showUnsavedExitModal}
        title="Изменения не сохранены"
        description="Изменения не сохранены. Уверены что хотите выйти?"
        onClose={() => {
          setShowUnsavedExitModal(false);
          setPendingExit(null);
        }}
        actions={
          <>
            <button
              type="button"
              className="btn btn--primary"
              onClick={() => handleSaveRole({ exitAfterSave: true })}
              disabled={isSavingRole}
            >
              <SvgIcon name="save" />
              <span>{isSavingRole ? "Сохранение..." : "Сохранить изменения"}</span>
            </button>

            <button
              type="button"
              className="btn btn--ghost"
              onClick={handleExitWithoutSaving}
              disabled={isSavingRole}
            >
              Выйти без изменений
            </button>
          </>
        }
      />

      {toast ? (
        <div className={`role-system-toast role-system-toast--${toast.type}`}>{toast.message}</div>
      ) : null}
    </div>
  );
}
