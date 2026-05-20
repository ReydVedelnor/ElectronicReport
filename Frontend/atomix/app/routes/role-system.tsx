import React, { useEffect, useMemo, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router";
import { SvgIcon } from "~/components/svg-icon";
import { duplicateRole, getRoleParticipantsCount, mapModuleSlugsToPermissionIds, type RoleItem } from "../components/roleActions";
import {
  activateRoleOnApi,
  createRoleOnApi,
  deactivateRoleOnApi,
  fetchEmployeesFromApi,
  fetchRolesFromApi,
  hydrateRoles,
  normalizeRoleName,
  saveRolesCache,
  type EmployeeRecord
} from "../components/roleApi";
import { getStoredAuthUser } from "../lib/auth";
import RoleSystemEditorPage from "./role-system-editor";

type ToastState = {
  message: string;
  type: "success" | "info";
};

type ActivityFilterValue = "all" | "true" | "false";

const ACTIVITY_FILTER_OPTIONS: Array<{ value: ActivityFilterValue; label: string; description: string }> = [
  { value: "all", label: "Все роли", description: "Показывать активные и деактивированные роли" },
  { value: "true", label: "Активные", description: "Показывать только активные роли" },
  { value: "false", label: "Деактивированные", description: "Показывать только деактивированные роли" }
];

export default function RoleSystemPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const searchParams = new URLSearchParams(location.search);
  const editorMode = searchParams.get("mode");
  const editorRoleId = searchParams.get("roleId");
  const shouldOpenEditor = editorMode === "new" || Boolean(editorRoleId);

  const authUser = useMemo(() => getStoredAuthUser(), []);
  const filterMenuRef = useRef<HTMLDivElement | null>(null);

  const [roles, setRoles] = useState<RoleItem[]>([]);
  const [employees, setEmployees] = useState<EmployeeRecord[]>([]);
  const [searchValue, setSearchValue] = useState("");
  const [activityFilter, setActivityFilter] = useState<ActivityFilterValue>("all");
  const [isFilterMenuOpen, setIsFilterMenuOpen] = useState(false);
  const [toast, setToast] = useState<ToastState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSavingRole, setIsSavingRole] = useState(false);
  const [changingActivityRoleId, setChangingActivityRoleId] = useState<string | null>(null);
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
      setRoles([]);
      setEmployees([]);
      setErrorMessage("Не удалось определить текущего пользователя.");
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      setErrorMessage("");

      const [apiRoles, apiEmployees] = await Promise.all([
        fetchRolesFromApi(authUser.userId),
        fetchEmployeesFromApi(authUser.userId)
      ]);

      const preparedRoles = hydrateRoles(
        apiRoles.map((role) => {
          const isCurrentUserRole =
            authUser.roleId === (role.backendRoleId ?? role.id) ||
            normalizeRoleName(authUser.roleName) === normalizeRoleName(role.name);

          if (role.permissions.length > 0 || !isCurrentUserRole || currentRolePermissions.length === 0) {
            return role;
          }

          return {
            ...role,
            permissions: currentRolePermissions,
            permissionsConfigured: true
          };
        }),
        apiEmployees
      );

      setEmployees(apiEmployees);
      setRoles(preparedRoles);
      saveRolesCache(preparedRoles);
    } catch (error) {
      console.error("Ошибка загрузки ролей:", error);
      setRoles([]);
      setEmployees([]);
      setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить роли");
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (!shouldOpenEditor) {
      loadData();
    }
  }, [authUser?.roleId, authUser?.roleName, authUser?.userId, currentRolePermissions, shouldOpenEditor]);

  useEffect(() => {
    if (!toast) return undefined;
    const timeoutId = window.setTimeout(() => setToast(null), 2200);
    return () => window.clearTimeout(timeoutId);
  }, [toast]);

  useEffect(() => {
    saveRolesCache(roles);
  }, [roles]);

  useEffect(() => {
    if (!isFilterMenuOpen) {
      return undefined;
    }

    const handlePointerDown = (event: MouseEvent) => {
      if (!filterMenuRef.current) return;
      if (filterMenuRef.current.contains(event.target as Node)) return;
      setIsFilterMenuOpen(false);
    };

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        setIsFilterMenuOpen(false);
      }
    };

    document.addEventListener("mousedown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);

    return () => {
      document.removeEventListener("mousedown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [isFilterMenuOpen]);

  const filteredRoles = useMemo(() => {
    const normalized = searchValue.trim().toLowerCase();

    return roles.filter((role) => {
      const isRoleActive = role.isActive !== false;
      const matchesActivity =
        activityFilter === "all" ||
        (activityFilter === "true" && isRoleActive) ||
        (activityFilter === "false" && !isRoleActive);
      const matchesSearch = !normalized || role.name.toLowerCase().includes(normalized);

      return matchesActivity && matchesSearch;
    });
  }, [roles, searchValue, activityFilter]);

  const activeFilterLabel =
    ACTIVITY_FILTER_OPTIONS.find((option) => option.value === activityFilter && option.value !== "all")?.label ?? "";

  const hasActiveFilters = activityFilter !== "all";

  if (shouldOpenEditor) {
    return <RoleSystemEditorPage />;
  }

  const handleAddRole = () => {
    navigate("/role-system?mode=new");
  };

  const handleToggleRoleActivity = async (role: RoleItem) => {
    const roleId = role.backendRoleId ?? role.id;
    if (!roleId) return;

    const isRoleInactive = role.isActive === false;
    const nextIsActive = isRoleInactive;
    const roleName = role.name || "Без названия";
    const actionLabel = nextIsActive ? "Активировать" : "Деактивировать";
    const confirmed = window.confirm(`${actionLabel} роль "${roleName}"?`);
    if (!confirmed) return;

    try {
      setChangingActivityRoleId(roleId);
      if (nextIsActive) {
        await activateRoleOnApi(roleId);
      } else {
        await deactivateRoleOnApi(roleId);
      }

      const nextRoles = roles.map((item) =>
        (item.backendRoleId ?? item.id) === roleId ? { ...item, isActive: nextIsActive } : item
      );
      setRoles(nextRoles);
      saveRolesCache(nextRoles);
      showToast(nextIsActive ? "Роль активирована." : "Роль деактивирована.");
    } catch (error) {
      console.error("Ошибка изменения состояния роли:", error);
      showToast(error instanceof Error ? error.message : "Не удалось изменить состояние роли.", "info");
    } finally {
      setChangingActivityRoleId(null);
    }
  };

  const handleDuplicateRole = async (roleId: string) => {
    const sourceRole = roles.find((role) => role.id === roleId);
    if (!sourceRole) return;

    const duplicatedRoles = duplicateRole(roles, roleId);
    const duplicatedRole = duplicatedRoles[duplicatedRoles.length - 1];
    const roleToCreate = {
      ...duplicatedRole,
      permissions: sourceRole.permissions,
      permissionsConfigured: true
    };

    try {
      setIsSavingRole(true);
      const createdRole = await createRoleOnApi(roleToCreate.name, roleToCreate.permissions, roleToCreate.description ?? "");
      const nextRoles = hydrateRoles([...roles, createdRole], employees);
      setRoles(nextRoles);
      saveRolesCache(nextRoles);
      showToast("Копия роли создана.");
    } catch (error) {
      console.error("Ошибка копирования роли:", error);
      showToast(error instanceof Error ? error.message : "Не удалось скопировать роль.", "info");
    } finally {
      setIsSavingRole(false);
    }
  };

  const applyActivityFilter = (value: ActivityFilterValue) => {
    setActivityFilter(value);
    setIsFilterMenuOpen(false);
  };

  const resetFilters = () => {
    setActivityFilter("all");
    setIsFilterMenuOpen(false);
  };

  return (
    <div className="role-system-page">
      <div className="role-system-toolbar role-system-toolbar--list">
        <button type="button" className="btn btn--primary" onClick={handleAddRole} disabled={isSavingRole}>
          <SvgIcon name="add" />
          <span>Новая роль</span>
        </button>

        <div className="ui-search role-system-searchbar">
          <span className="ui-search__icon">
            <SvgIcon name="search" />
          </span>
          <input
            className="ui-search__input"
            type="text"
            placeholder="Поиск..."
            value={searchValue}
            onChange={(event) => setSearchValue(event.target.value)}
          />
        </div>

        <div className="ui-filter-menu role-system-filter-menu" ref={filterMenuRef}>
          <button
            type="button"
            className={`ui-filter-menu__trigger ${isFilterMenuOpen ? "ui-filter-menu__trigger--open" : ""}`}
            aria-haspopup="dialog"
            aria-expanded={isFilterMenuOpen}
            aria-label="Открыть фильтры"
            onClick={() => setIsFilterMenuOpen((prev) => !prev)}
          >
            <span className="ui-filter-menu__trigger-icon">
              <SvgIcon name="filter" />
            </span>
            <span>Фильтры</span>
            {hasActiveFilters ? <span className="ui-filter-menu__counter">1</span> : null}
            <SvgIcon name="chevron-down" className="ui-filter-menu__trigger-chevron" />
          </button>

          {isFilterMenuOpen ? (
            <div className="ui-filter-menu__panel" role="dialog" aria-label="Фильтр ролей">
              <aside className="ui-filter-menu__sidebar" aria-label="Разделы фильтрации">
                <div className="ui-filter-menu__sidebar-title">Фильтры</div>
                <button
                  type="button"
                  className="ui-filter-menu__section ui-filter-menu__section--active"
                  aria-current="true"
                >
                  Состояние роли
                </button>
              </aside>

              <div className="ui-filter-menu__content">
                <div className="ui-filter-menu__content-head">
                  <div className="ui-filter-menu__content-copy">
                    <h3 className="ui-filter-menu__content-title">Состояние роли</h3>
                    
                  </div>

                  <button type="button" className="ui-filter-menu__reset" onClick={resetFilters}>
                    Сбросить
                  </button>
                </div>

                <div className="ui-filter-menu__options">
                  {ACTIVITY_FILTER_OPTIONS.map((option) => {
                    const isSelected = activityFilter === option.value;

                    return (
                      <button
                        key={option.value}
                        type="button"
                        className={`ui-filter-menu__option ${isSelected ? "ui-filter-menu__option--active" : ""}`}
                        onClick={() => applyActivityFilter(option.value)}
                      >
                        <span className="ui-filter-menu__option-copy">
                          <span className="ui-filter-menu__option-title">{option.label}</span>
                          <span className="ui-filter-menu__option-description">{option.description}</span>
                        </span>
                        {isSelected ? (
                          <span className="ui-filter-menu__option-mark">
                            <SvgIcon name="check" />
                          </span>
                        ) : null}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      {activeFilterLabel ? (
        <div className="ui-toolbar-meta role-system-toolbar-meta">
          <div className="ui-filter-chip">
            <span className="ui-filter-chip__icon">
              <SvgIcon name="filter" />
            </span>
            <span>{activeFilterLabel}</span>
            <button
              type="button"
              className="ui-filter-chip__remove"
              title="Сбросить фильтр"
              aria-label="Сбросить фильтр"
              onClick={() => setActivityFilter("all")}
            >
              <SvgIcon name="close" />
            </button>
          </div>
        </div>
      ) : null}

      <section className="ui-card role-system-card role-system-card--list">
        <div className="ui-card__header">
          <h2 className="ui-card__title">Список ролей</h2>
        </div>

        <div className="ui-table-wrap">
          <table className="ui-table role-system-table role-system-table--list">
            <thead>
              <tr>
                <th className="role-system-table__num">№</th>
                <th className="role-system-table__role">Роли</th>
                <th className="role-system-table__participants">Участники</th>
                <th className="role-system-table__status">Состояние</th>
                <th className="role-system-table__actions">Действия</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="ui-empty">
                    Загрузка ролей...
                  </td>
                </tr>
              ) : errorMessage ? (
                <tr>
                  <td colSpan={5} className="ui-empty">
                    {errorMessage}
                  </td>
                </tr>
              ) : filteredRoles.length > 0 ? (
                filteredRoles.map((role, index) => {
                  const isRoleInactive = role.isActive === false;
                  const isRoleActivityChanging = changingActivityRoleId === (role.backendRoleId ?? role.id);

                  return (
                    <tr key={role.id}>
                      <td>{index + 1}</td>
                      <td className="role-system-role-name">{role.name || "Без названия"}</td>
                      <td className="role-system-role-count">{getRoleParticipantsCount(role)}</td>
                      <td className="role-system-status-cell">
                        <span className={`status-badge ${isRoleInactive ? "status-badge--danger" : "status-badge--success"}`}>
                          <SvgIcon name={isRoleInactive ? "close" : "check"} />
                          <span>{isRoleInactive ? "Деактивирована" : "Активна"}</span>
                        </span>
                      </td>
                      <td>
                        <div className="action-buttons role-system-actions">
                          <button
                            type="button"
                            className="icon-btn icon-btn--edit"
                            title="Редактировать"
                            onClick={() => navigate(`/role-system?roleId=${encodeURIComponent(role.id)}`)}
                          >
                            <SvgIcon name="edit" />
                          </button>

                          <button
                            type="button"
                            className={`icon-btn role-system-action-btn ${
                              isRoleInactive ? "role-system-action-btn--activate" : "role-system-action-btn--deactivate"
                            }`}
                            title={isRoleInactive ? "Активировать" : "Деактивировать"}
                            aria-label={isRoleInactive ? "Активировать роль" : "Деактивировать роль"}
                            onClick={() => handleToggleRoleActivity(role)}
                            disabled={isRoleActivityChanging || isSavingRole}
                          >
                            <SvgIcon name={isRoleInactive ? "check" : "close"} />
                          </button>

                          <button
                            type="button"
                            className="icon-btn role-system-action-btn role-system-action-btn--copy"
                            title="Копировать роль"
                            onClick={() => handleDuplicateRole(role.id)}
                            disabled={isSavingRole}
                          >
                            <SvgIcon name="copy" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={5} className="ui-empty">
                    Роли не найдены
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {toast ? (
        <div className={`role-system-toast role-system-toast--${toast.type}`}>{toast.message}</div>
      ) : null}
    </div>
  );
}
