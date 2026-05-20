import React, { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router";
import type { LoaderFunctionArgs } from "react-router";
import { AppModal } from "~/components/app-modal";
import { SvgIcon } from "~/components/svg-icon";
import { getApiBaseUrl, getStoredAuthUser } from "~/lib/auth";

import { searchEmployees, type Employee } from "../components/employeeActions";

export async function loader({ request }: LoaderFunctionArgs) {
  return null;
}

type BackendEmployeeItem = {
  userId: string;
  fullName: string;
  login: string;
  roleId?: string;
  roleName: string;
  isRoleActive?: boolean | string | number | null;
  roleIsActive?: boolean | string | number | null;
  roleActive?: boolean | string | number | null;
  is_role_active?: boolean | string | number | null;
  role?: {
    isActive?: boolean | string | number | null;
  } | null;
  departmentId?: string;
  departmentName: string;
  isDepartmentActive?: boolean | string | number | null;
  isActive: boolean | string | number | null;
};

type BackendEmployeesResponse = {
  items?: BackendEmployeeItem[];
};

type FilterRole = {
  roleId: string;
  name: string;
  description: string;
};

type FilterDepartment = {
  departmentId: string;
  parentDepartmentId: string;
  name: string;
  shortName: string;
  hierarchyLevel: number;
};

type FilterContextResponse = {
  roles: FilterRole[];
  departments: FilterDepartment[];
  activityOptions: Array<{ code: string; name: string }>;
  defaults: {
    activity: string;
  };
};

type EmployeeViewModel = {
  id: number;
  userId: string;
  name: string;
  fullName: string;
  login: string;
  position: string;
  role: string;
  roleId: string;
  office: string;
  department: string;
  departmentId: string;
  isActive: boolean;
  roleIsActive: boolean;
  lastName: string;
  firstName: string;
  middleName: string;
  source: "api" | "local";
};

type EmployeeOverride = Partial<EmployeeViewModel> & {
  userId: string;
};

type SelectedFilters = {
  roleIds: string[];
  departmentIds: string[];
  activity: string; // "all", "active", "inactive"
};

function getEmployeesApiUrl(filters: SelectedFilters, searchQuery: string = ""): string {
  const authUser = getStoredAuthUser();
  const userId = authUser?.userId;

  if (!userId) {
    throw new Error("Не найден userId в localStorage");
  }

  const params = new URLSearchParams({
    userId,
    page: "0",
    size: "100",
  });

  if (filters.roleIds.length > 0) {
    filters.roleIds.forEach(roleId => {
      params.append("roleIds", roleId);
    });
  }

  if (filters.departmentIds.length > 0) {
    filters.departmentIds.forEach(deptId => {
      params.append("departmentIds", deptId);
    });
  }

  if (filters.activity === "active") {
    params.append("activity", "true");
  } else if (filters.activity === "inactive") {
    params.append("activity", "false");
  }

  if (searchQuery) {
    params.append("search", searchQuery);
  }

  return `${getApiBaseUrl()}/api/employees?${params.toString()}`;
}

function getFilterContextApiUrl(): string {
  const authUser = getStoredAuthUser();
  const userId = authUser?.userId;

  if (!userId) {
    throw new Error("Не найден userId в localStorage");
  }

  return `${getApiBaseUrl()}/api/employees/filter-context?userId=${userId}`;
}

const LOCAL_CREATED_KEY = "employees-created";
const LOCAL_OVERRIDES_KEY = "employees-overrides";
const LOCAL_HIDDEN_KEY = "employees-hidden";

function splitFullName(fullName: string) {
  const [lastName = "", firstName = "", middleName = ""] = String(fullName || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  return { lastName, firstName, middleName };
}

function parseActiveFlag(value: unknown, fallback = true): boolean {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value === 1;

  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();

    if (["true", "1", "active", "активен", "активна"].includes(normalized)) return true;
    if (["false", "0", "inactive", "неактивен", "неактивна"].includes(normalized)) return false;
  }

  return fallback;
}

function getRoleIsActive(item: BackendEmployeeItem): boolean {
  if (item.isRoleActive !== undefined && item.isRoleActive !== null) {
    return parseActiveFlag(item.isRoleActive, true);
  }

  if (item.roleIsActive !== undefined && item.roleIsActive !== null) {
    return parseActiveFlag(item.roleIsActive, true);
  }

  if (item.roleActive !== undefined && item.roleActive !== null) {
    return parseActiveFlag(item.roleActive, true);
  }

  if (item.is_role_active !== undefined && item.is_role_active !== null) {
    return parseActiveFlag(item.is_role_active, true);
  }

  if (item.role?.isActive !== undefined && item.role?.isActive !== null) {
    return parseActiveFlag(item.role.isActive, true);
  }

  return true;
}

function normalizeEmployeeViewModel(employee: Partial<EmployeeViewModel>): EmployeeViewModel {
  const fullName = String(employee.fullName || employee.name || "").trim();
  const parts = splitFullName(fullName);

  return {
    id: Number(employee.id || 0),
    userId: String(employee.userId || employee.id || crypto.randomUUID()),
    name: fullName,
    fullName,
    login: String(employee.login || ""),
    position: String(employee.position || employee.role || ""),
    role: String(employee.role || employee.position || ""),
    roleId: String(employee.roleId || ""),
    office: String(employee.office || employee.department || ""),
    department: String(employee.department || employee.office || ""),
    departmentId: String(employee.departmentId || ""),
    isActive: parseActiveFlag(employee.isActive, true),
    roleIsActive: parseActiveFlag(employee.roleIsActive, true),
    lastName: String(employee.lastName || parts.lastName || ""),
    firstName: String(employee.firstName || parts.firstName || ""),
    middleName: String(employee.middleName || parts.middleName || ""),
    source: employee.source === "api" ? "api" : "local",
  };
}

function backendEmployeeToViewModel(item: BackendEmployeeItem, index = 0): EmployeeViewModel {
  const parts = splitFullName(item.fullName);

  return {
    id: index + 1,
    userId: item.userId,
    name: item.fullName,
    fullName: item.fullName,
    login: item.login || "",
    position: item.roleName || "",
    role: item.roleName || "",
    roleId: item.roleId || "",
    office: item.departmentName || "",
    department: item.departmentName || "",
    departmentId: item.departmentId || "",
    isActive: parseActiveFlag(item.isActive, true),
    roleIsActive: getRoleIsActive(item),
    lastName: parts.lastName,
    firstName: parts.firstName,
    middleName: parts.middleName,
    source: "api",
  };
}

function readJson<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;

  try {
    const raw = window.localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function writeJson<T>(key: string, value: T) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(key, JSON.stringify(value));
}

function getLocalCreatedEmployees(): EmployeeViewModel[] {
  return readJson<EmployeeViewModel[]>(LOCAL_CREATED_KEY, []);
}

function getEmployeeOverrides(): Record<string, EmployeeOverride> {
  return readJson<Record<string, EmployeeOverride>>(LOCAL_OVERRIDES_KEY, {});
}

function getHiddenEmployeeIds(): string[] {
  return readJson<string[]>(LOCAL_HIDDEN_KEY, []);
}

function saveHiddenEmployeeIds(value: string[]) {
  writeJson(LOCAL_HIDDEN_KEY, value);
}

function hideEmployee(userId: string) {
  const hidden = new Set(getHiddenEmployeeIds());
  hidden.add(userId);
  saveHiddenEmployeeIds([...hidden]);
}

function mergeEmployees(apiEmployees: EmployeeViewModel[]): EmployeeViewModel[] {
  const hiddenIds = new Set(getHiddenEmployeeIds());
  const overrides = getEmployeeOverrides();
  const created = getLocalCreatedEmployees();

  const mergedApi = apiEmployees
    .filter((employee) => !hiddenIds.has(employee.userId))
    .map((employee) => {
      const override = overrides[employee.userId];
      const merged = override ? { ...employee, ...override, source: employee.source } : employee;
      return normalizeEmployeeViewModel(merged);
    });

  const mergedCreated = created
    .filter((employee) => !hiddenIds.has(employee.userId))
    .map((employee) => normalizeEmployeeViewModel(employee));

  const map = new Map<string, EmployeeViewModel>();
  [...mergedApi, ...mergedCreated].forEach((employee, index) => {
    map.set(employee.userId, { ...employee, id: index + 1 });
  });

  return [...map.values()];
}

async function fetchEmployeesFromApi(filters: SelectedFilters, searchQuery: string = "", signal?: AbortSignal): Promise<EmployeeViewModel[]> {
  const response = await fetch(getEmployeesApiUrl(filters, searchQuery), { signal });

  if (!response.ok) {
    throw new Error(`Ошибка загрузки сотрудников: ${response.status}`);
  }

  const data: BackendEmployeesResponse = await response.json();
  const items = Array.isArray(data.items) ? data.items : [];
  return items.map((item, index) => backendEmployeeToViewModel(item, index));
}

async function fetchFilterContext(signal?: AbortSignal): Promise<FilterContextResponse> {
  const response = await fetch(getFilterContextApiUrl(), { signal });

  if (!response.ok) {
    throw new Error(`Ошибка загрузки фильтров: ${response.status}`);
  }

  return response.json();
}

async function deactivateEmployee(employeeId: string, updatedByUserId: string): Promise<void> {
  const response = await fetch(`${getApiBaseUrl()}/api/employees/${employeeId}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      updatedByUserId,
      isActive: false,
    }),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    let errorMessage = `Ошибка деактивации сотрудника: ${response.status}`;
    try {
      const parsed = JSON.parse(text);
      errorMessage = parsed.message || parsed.error || errorMessage;
    } catch {
      if (text) errorMessage = text;
    }
    throw new Error(errorMessage);
  }
}

export default function EmployeesPage() {
  const navigate = useNavigate();
  const location = useLocation();

  const [employees, setEmployees] = useState<EmployeeViewModel[]>([]);
  const [searchValue, setSearchValue] = useState("");
  const [selectedFilters, setSelectedFilters] = useState<SelectedFilters>({ roleIds: [], departmentIds: [], activity: "all" });
  const [tempSelectedFilters, setTempSelectedFilters] = useState<SelectedFilters>({ roleIds: [], departmentIds: [], activity: "all" });
  
  const [roleFilters, setRoleFilters] = useState<FilterRole[]>([]);
  const [departmentFilters, setDepartmentFilters] = useState<FilterDepartment[]>([]);
  const [activityOptions, setActivityOptions] = useState<Array<{ code: string; name: string }>>([]);
  
  const [isFilterModalOpen, setIsFilterModalOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [deactivatingEmployee, setDeactivatingEmployee] = useState<EmployeeViewModel | null>(null);
  const [isDeactivating, setIsDeactivating] = useState(false);

  const hasActiveFilters = selectedFilters.roleIds.length > 0 || selectedFilters.departmentIds.length > 0 || selectedFilters.activity !== "all";

  const loadFilterContext = async (signal?: AbortSignal) => {
    try {
      const filterContext = await fetchFilterContext(signal);
      
      setRoleFilters(filterContext.roles || []);
      setDepartmentFilters(filterContext.departments || []);
      const filteredOptions = (filterContext.activityOptions || []).filter(option => option.code !== "all");
      setActivityOptions(filteredOptions);
      
      if (filterContext.defaults?.activity) {
        const defaultActivity = filterContext.defaults.activity === "true" ? "active" : 
                                filterContext.defaults.activity === "false" ? "inactive" : "all";
        setSelectedFilters(prev => ({ ...prev, activity: defaultActivity }));
        setTempSelectedFilters(prev => ({ ...prev, activity: defaultActivity }));
      }
    } catch (error) {
      if (signal?.aborted) return;
      console.error("Ошибка загрузки фильтров:", error);
      setRoleFilters([]);
      setDepartmentFilters([]);
    }
  };

  const loadEmployees = async (filters: SelectedFilters, search: string, signal?: AbortSignal) => {
    try {
      setIsLoading(true);
      setIsError(false);
      setErrorMessage("");

      const apiEmployees = await fetchEmployeesFromApi(filters, search, signal);
      setEmployees(apiEmployees);
    } catch (error) {
      if (signal?.aborted) return;
      console.error("Ошибка загрузки сотрудников:", error);
      setEmployees([]);
      setIsError(true);
      setErrorMessage(error instanceof Error ? error.message : "Не удалось загрузить список сотрудников");
    } finally {
      if (!signal?.aborted) {
        setIsLoading(false);
      }
    }
  };

  const applyFilters = () => {
    setSelectedFilters(tempSelectedFilters);
    setIsFilterModalOpen(false);
  };

  const resetFilters = () => {
    const newFilters = { roleIds: [], departmentIds: [], activity: "all" };
    setSelectedFilters(newFilters);
    setTempSelectedFilters(newFilters);
    setIsFilterModalOpen(false);
  };

  const toggleTempRoleFilter = (roleId: string) => {
    setTempSelectedFilters(prev => {
      const current = [...prev.roleIds];
      const index = current.indexOf(roleId);
      
      if (index === -1) {
        current.push(roleId);
      } else {
        current.splice(index, 1);
      }
      
      return { ...prev, roleIds: current };
    });
  };

  const toggleTempDepartmentFilter = (departmentId: string) => {
    setTempSelectedFilters(prev => {
      const current = [...prev.departmentIds];
      const index = current.indexOf(departmentId);
      
      if (index === -1) {
        current.push(departmentId);
      } else {
        current.splice(index, 1);
      }
      
      return { ...prev, departmentIds: current };
    });
  };

  const setTempActivityFilter = (activity: string) => {
    setTempSelectedFilters(prev => ({ ...prev, activity }));
  };

  useEffect(() => {
    const controller = new AbortController();
    
    const initializeData = async () => {
      await loadFilterContext(controller.signal);
      await loadEmployees(selectedFilters, searchValue, controller.signal);
    };
    
    initializeData();
    
    return () => controller.abort();
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    
    const timeoutId = setTimeout(() => {
      loadEmployees(selectedFilters, searchValue, controller.signal);
    }, 300);
    
    return () => {
      clearTimeout(timeoutId);
      controller.abort();
    };
  }, [selectedFilters, searchValue]);

  useEffect(() => {
    if (location.state?.refresh) {
      loadEmployees(selectedFilters, searchValue);
    }
  }, [location.state]);

  const handleAddEmployee = () => {
    navigate("/employees-modal");
  };

  const handleEdit = (employee: EmployeeViewModel) => {
    navigate(`/employees/edit/${employee.userId}`, { state: { employee } });
  };

  const confirmDeactivate = async () => {
    if (!deactivatingEmployee) return;
    
    try {
      setIsDeactivating(true);
      const authUser = getStoredAuthUser();
      await deactivateEmployee(deactivatingEmployee.userId, authUser?.userId || "");
      
      // Удаляем сотрудника из списка после успешной деактивации
      setEmployees(prevEmployees => 
        prevEmployees.filter(emp => emp.userId !== deactivatingEmployee.userId)
      );
      
      setDeactivatingEmployee(null);
    } catch (error) {
      console.error("Ошибка деактивации сотрудника:", error);
      setErrorMessage(error instanceof Error ? error.message : "Не удалось деактивировать сотрудника");
      setIsError(true);
    } finally {
      setIsDeactivating(false);
    }
  };

  const sortedEmployees = useMemo(() => {
    return [...employees].sort((a, b) => {
      if (a.isActive !== b.isActive) {
        return a.isActive ? -1 : 1;
      }

      const departmentCompare = (a.department || "").localeCompare(b.department || "", "ru");
      if (departmentCompare !== 0) return departmentCompare;

      const roleCompare = (a.role || "").localeCompare(b.role || "", "ru");
      if (roleCompare !== 0) return roleCompare;

      const lastNameCompare = (a.lastName || "").localeCompare(b.lastName || "", "ru");
      if (lastNameCompare !== 0) return lastNameCompare;

      const firstNameCompare = (a.firstName || "").localeCompare(b.firstName || "", "ru");
      if (firstNameCompare !== 0) return firstNameCompare;

      const middleNameCompare = (a.middleName || "").localeCompare(b.middleName || "", "ru");
      if (middleNameCompare !== 0) return middleNameCompare;

      return (a.userId || "").localeCompare(b.userId || "", "ru");
    });
  }, [employees]);

  const getActiveFiltersLabel = () => {
    const labels: string[] = [];
    
    selectedFilters.roleIds.forEach(roleId => {
      const role = roleFilters.find(r => r.roleId === roleId);
      if (role) labels.push(role.name);
    });
    
    selectedFilters.departmentIds.forEach(deptId => {
      const dept = departmentFilters.find(d => d.departmentId === deptId);
      if (dept) labels.push(dept.name);
    });
    
    if (selectedFilters.activity === "active") labels.push("Активные");
    if (selectedFilters.activity === "inactive") labels.push("Неактивные");
    
    return labels.join(", ");
  };

  const activeFilterLabel = getActiveFiltersLabel();

  return (
    <div className="ui-page employees-page">
      <div className="ui-toolbar employees-toolbar">
        <div className="ui-toolbar__group employees-toolbar__group employees-toolbar__group--main">
          <button className="btn btn--primary" type="button" onClick={handleAddEmployee}>
            <SvgIcon name="add" />
            <span>Добавить сотрудника</span>
          </button>
        </div>

        <div className="ui-toolbar__group employees-toolbar__group employees-toolbar__group--search">
          <div className="ui-search employees-search">
            <span className="ui-search__icon">
              <SvgIcon name="search" />
            </span>
            <input
              className="ui-search__input"
              type="text"
              placeholder="Поиск сотрудников..."
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
            />
            <button
              className="ui-search__action"
              type="button"
              title="Открыть фильтр"
              onClick={() => {
                setTempSelectedFilters(selectedFilters);
                setIsFilterModalOpen(true);
              }}
            >
              <SvgIcon name="filter" />
              {hasActiveFilters ? <span className="filter-badge" /> : null}
            </button>
          </div>
        </div>
      </div>

      {hasActiveFilters ? (
        <div className="employees-toolbar-meta">
          <div className="active-filter-chip">
            <span className="chip-icon">
              <SvgIcon name="filter" />
            </span>
            <span>{activeFilterLabel}</span>
            <button
              className="chip-remove"
              type="button"
              onClick={resetFilters}
              title="Сбросить фильтр"
            >
              <SvgIcon name="close" />
            </button>
          </div>
        </div>
      ) : null}

      <div className="ui-card employees-card">
        <div className="ui-card__header employees-card__header">
          <div>
            <h2 className="ui-card__title">Список сотрудников</h2>
          </div>
          <div className="employees-card__meta">Всего: {sortedEmployees.length}</div>
        </div>

        <div className="ui-table-wrap">
          <table className="ui-table employees-table">
            <thead>
              <tr>
                <th>№</th>
                <th>Фамилия</th>
                <th>Имя</th>
                <th>Отчество</th>
                <th>Роль доступа</th>
                <th>Подразделение</th>
                <th>Статус</th>
                <th>Действия</th>
              </tr>
            </thead>

            <tbody>
              {isLoading ? (
                <tr>
                  <td colSpan={8} className="ui-empty">Загрузка сотрудников...</td>
                </tr>
              ) : isError && sortedEmployees.length === 0 ? (
                <tr>
                  <td colSpan={8} className="ui-empty">{errorMessage || "Ошибка загрузки сотрудников"}</td>
                </tr>
              ) : sortedEmployees.length > 0 ? (
                sortedEmployees.map((employee, index) => (
                  <tr key={employee.userId}>
                    <td className="employee-number">{index + 1}</td>
                    <td>{employee.lastName || "—"}</td>
                    <td>{employee.firstName || "—"}</td>
                    <td>{employee.middleName || "—"}</td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span className={`role-badge ${employee.roleIsActive ? 'role-active' : 'role-inactive'}`}>
                          {employee.role || '—'}
                        </span>
                        {!employee.roleIsActive && (
                          <span className="role-status-inactive-text">(неактивна)</span>
                        )}
                      </div>
                    </td>
                    <td>{employee.department || "—"}</td>
                    <td className="status-cell">
                      <span className={`status-badge ${employee.isActive ? "status-active" : "status-inactive"}`}>
                        <SvgIcon name={employee.isActive ? "check" : "close"} />
                        <span>{employee.isActive ? "Активен" : "Неактивен"}</span>
                      </span>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <button className="icon-btn icon-btn--edit" onClick={() => handleEdit(employee)} title="Редактировать" type="button">
                          <SvgIcon name="edit" />
                        </button>

                        <button 
                          className="icon-btn icon-btn--delete" 
                          onClick={() => setDeactivatingEmployee(employee)} 
                          title="Деактивировать" 
                          type="button"
                        >
                          <SvgIcon name="delete" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="ui-empty">Сотрудники не найдены</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Модальное окно фильтров */}
      <AppModal
        open={isFilterModalOpen}
        title="Фильтры"
        onClose={() => setIsFilterModalOpen(false)}
        actions={
          <>
            <button type="button" className="btn btn--ghost" onClick={resetFilters}>
              Сбросить все
            </button>
            <button type="button" className="btn btn--secondary" onClick={() => setIsFilterModalOpen(false)}>
              Отмена
            </button>
            <button type="button" className="btn btn--primary" onClick={applyFilters}>
              Применить фильтры
            </button>
          </>
        }
      >
        <div className="employees-filter-container">
          {roleFilters.length > 0 && (
            <div className="filter-section">
              <h4 className="filter-section-title">Роли доступа</h4>
              <div className="filter-checkboxes">
                {roleFilters.map((role) => {
                  const isChecked = tempSelectedFilters.roleIds.includes(role.roleId);
                  return (
                    <label key={role.roleId} className="filter-checkbox-label">
                      <input
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => toggleTempRoleFilter(role.roleId)}
                      />
                      <span>{role.name}</span>
                    </label>
                  );
                })}
              </div>
            </div>
          )}

          {departmentFilters.length > 0 && (
            <div className="filter-section">
              <h4 className="filter-section-title">Подразделения</h4>
              <div className="filter-checkboxes">
                {departmentFilters.map((dept) => {
                  const isChecked = tempSelectedFilters.departmentIds.includes(dept.departmentId);
                  return (
                    <label key={dept.departmentId} className="filter-checkbox-label">
                      <input
                        type="checkbox"
                        checked={isChecked}
                        onChange={() => toggleTempDepartmentFilter(dept.departmentId)}
                      />
                      <span>{dept.name}</span>
                    </label>
                  );
                })}
              </div>
            </div>
          )}

          <div className="filter-section">
            <h4 className="filter-section-title">Статус сотрудника</h4>
            <div className="filter-radios">
              <label className="filter-radio-label">
                <input
                  type="radio"
                  name="activity"
                  value="all"
                  checked={tempSelectedFilters.activity === "all"}
                  onChange={() => setTempActivityFilter("all")}
                />
                <span>Все сотрудники</span>
              </label>
              <label className="filter-radio-label">
                <input
                  type="radio"
                  name="activity"
                  value="active"
                  checked={tempSelectedFilters.activity === "active"}
                  onChange={() => setTempActivityFilter("active")}
                />
                <span>Активные</span>
              </label>
              <label className="filter-radio-label">
                <input
                  type="radio"
                  name="activity"
                  value="inactive"
                  checked={tempSelectedFilters.activity === "inactive"}
                  onChange={() => setTempActivityFilter("inactive")}
                />
                <span>Неактивные</span>
              </label>
            </div>
          </div>
        </div>
      </AppModal>

      {/* Модальное окно подтверждения деактивации */}
      <AppModal
        open={Boolean(deactivatingEmployee)}
        title="Подтвердите деактивацию"
        description={
          deactivatingEmployee
            ? `Сотрудник «${deactivatingEmployee.fullName}» будет деактивирован и удалён из списка.`
            : undefined
        }
        onClose={() => setDeactivatingEmployee(null)}
        bodyAlign="center"
        actions={
          <>
            <button type="button" className="btn btn--ghost" onClick={() => setDeactivatingEmployee(null)} disabled={isDeactivating}>
              Отмена
            </button>
            <button type="button" className="btn btn--danger" onClick={confirmDeactivate} disabled={isDeactivating}>
              {isDeactivating ? "Деактивация..." : "Деактивировать"}
            </button>
          </>
        }
      />
    </div>
  );
}