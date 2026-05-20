import React, { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router";
import type { LoaderFunctionArgs } from "react-router";
import { AppModal } from "~/components/app-modal";
import { SvgIcon } from "~/components/svg-icon";
import { getApiBaseUrl, getStoredAuthUser } from "~/lib/auth";

export async function loader({ request }: LoaderFunctionArgs) {
  return null;
}

type BackendRoleOption = {
  roleId: string;
  name: string;
  description?: string;
  isActive?: boolean;
};

type BackendDepartmentOption = {
  departmentId: string;
  parentDepartmentId?: string;
  name: string;
  shortName?: string;
  hierarchyLevel?: number;
  isActive?: boolean;
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
  lastName: string;
  firstName: string;
  middleName: string;
  source: "api" | "local";
};

type BackendEmployeeItem = {
  userId: string;
  fullName: string;
  login: string;
  roleId?: string;
  roleName: string;
  departmentId?: string;
  departmentName: string;
  isActive: boolean;
};

type BackendEmployeesResponse = {
  items?: BackendEmployeeItem[];
};

type EmployeeDetailsResponse = {
  employee?: {
    userId: string;
    lastName?: string;
    firstName?: string;
    middleName?: string;
    fullName?: string;
    login?: string;
    roleId?: string;
    roleName?: string;
    departmentId?: string;
    departmentName?: string;
    isActive?: boolean;
  };
  roles?: BackendRoleOption[];
  departments?: BackendDepartmentOption[];
};

type EmployeeCreateContextResponse = {
  departments?: BackendDepartmentOption[];
  roles?: BackendRoleOption[];
};

type FormData = {
  lastName: string;
  firstName: string;
  patronymic: string;
  roleId: string;
  departmentId: string;
  login: string;
  password: string;
};

type FormErrors = {
  lastName: boolean;
  firstName: boolean;
  roleId: boolean;
  departmentId: boolean;
  login: boolean;
  password: boolean;
};

function getCurrentUserId(): string {
  const authUser = getStoredAuthUser();
  const userId = authUser?.userId;

  if (!userId) {
    throw new Error("Не найден userId в localStorage");
  }

  return userId;
}

function splitFullName(fullName: string) {
  const [lastName = "", firstName = "", middleName = ""] = String(fullName || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  return { lastName, firstName, middleName };
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
    isActive: Boolean(item.isActive),
    lastName: parts.lastName,
    firstName: parts.firstName,
    middleName: parts.middleName,
    source: "api",
  };
}

function detailsToViewModel(data: EmployeeDetailsResponse): EmployeeViewModel | null {
  const employee = data.employee;
  if (!employee) return null;

  const fullName = employee.fullName || `${employee.lastName || ""} ${employee.firstName || ""} ${employee.middleName || ""}`.trim();

  return {
    id: 1,
    userId: employee.userId,
    name: fullName,
    fullName,
    login: employee.login || "",
    position: employee.roleName || "",
    role: employee.roleName || "",
    roleId: employee.roleId || "",
    office: employee.departmentName || "",
    department: employee.departmentName || "",
    departmentId: employee.departmentId || "",
    isActive: employee.isActive !== undefined ? Boolean(employee.isActive) : true,
    lastName: employee.lastName || splitFullName(fullName).lastName,
    firstName: employee.firstName || splitFullName(fullName).firstName,
    middleName: employee.middleName || splitFullName(fullName).middleName,
    source: "api",
  };
}

async function fetchCreateContext(): Promise<EmployeeCreateContextResponse> {
  const params = new URLSearchParams({ userId: getCurrentUserId() });
  const response = await fetch(`${getApiBaseUrl()}/api/employees/create-context?${params.toString()}`);

  if (!response.ok) {
    throw new Error(`Ошибка загрузки данных формы: ${response.status}`);
  }

  return response.json();
}

async function fetchEmployeeDetails(employeeId: string): Promise<EmployeeDetailsResponse> {
  const params = new URLSearchParams({ userId: getCurrentUserId() });
  const response = await fetch(`${getApiBaseUrl()}/api/employees/${employeeId}?${params.toString()}`);

  if (!response.ok) {
    throw new Error(`Ошибка загрузки сотрудника: ${response.status}`);
  }

  return response.json();
}

async function fetchEmployeesFromApi(): Promise<EmployeeViewModel[]> {
  const params = new URLSearchParams({
    userId: getCurrentUserId(),
    page: "0",
    size: "100",
  });

  const response = await fetch(`${getApiBaseUrl()}/api/employees?${params.toString()}`);

  if (!response.ok) {
    throw new Error(`Ошибка загрузки сотрудников: ${response.status}`);
  }

  const data: BackendEmployeesResponse = await response.json();
  const items = Array.isArray(data.items) ? data.items : [];
  return items.map((item, index) => backendEmployeeToViewModel(item, index));
}

async function readBackendError(response: Response): Promise<string> {
  const text = await response.text().catch(() => "");

  if (!text) return "";

  try {
    const parsed = JSON.parse(text) as { message?: string; error?: string };
    return parsed.message || parsed.error || text;
  } catch {
    return text;
  }
}

async function requestUpdateEmployee(url: string, method: "PATCH" | "PUT", payload: {
  updatedByUserId: string;
  lastName: string;
  firstName: string;
  middleName: string;
  roleId: string;
  departmentId: string;
  login: string;
  password?: string;
}) {
  const response = await fetch(url, {
    method,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const message = await readBackendError(response);
    throw new Error(message || `Ошибка сохранения сотрудника: ${response.status}`);
  }

  const text = await response.text().catch(() => "");
  return text ? JSON.parse(text) : {};
}

async function updateEmployee(employeeId: string, payload: {
  updatedByUserId: string;
  lastName: string;
  firstName: string;
  middleName: string;
  roleId: string;
  departmentId: string;
  login: string;
  password?: string;
}) {
  const baseUrl = getApiBaseUrl();
  const attempts: Array<{ url: string; method: "PATCH" | "PUT" }> = [
    { url: `${baseUrl}/api/employees/${employeeId}`, method: "PATCH" },
    { url: `${baseUrl}/api/employees/${employeeId}`, method: "PUT" },
    { url: `${baseUrl}/api/employees`, method: "PUT" },
  ];

  const errors: string[] = [];

  for (const attempt of attempts) {
    try {
      return await requestUpdateEmployee(attempt.url, attempt.method, payload);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      errors.push(`${attempt.method} ${attempt.url}: ${message}`);

      if (!message.toLowerCase().includes("method") && !message.toLowerCase().includes("not supported")) {
        break;
      }
    }
  }

  throw new Error(`Backend не принял сохранение сотрудника. ${errors.join(" | ")}`);
}

export default function EmployeeEditPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { id } = useParams();

  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [roleOptions, setRoleOptions] = useState<BackendRoleOption[]>([]);
  const [departmentOptions, setDepartmentOptions] = useState<BackendDepartmentOption[]>([]);
  const [currentEmployee, setCurrentEmployee] = useState<EmployeeViewModel | null>(null);
  const [showValidationModal, setShowValidationModal] = useState(false);
  const [formData, setFormData] = useState<FormData>({
    lastName: "",
    firstName: "",
    patronymic: "",
    roleId: "",
    departmentId: "",
    login: "",
    password: "",
  });

  const [errors, setErrors] = useState<FormErrors>({
    lastName: false,
    firstName: false,
    roleId: false,
    departmentId: false,
    login: false,
    password: false,
  });

  useEffect(() => {
    const loadEmployeeData = async () => {
      try {
        let employee = location.state?.employee as EmployeeViewModel | undefined;
        let roles: BackendRoleOption[] = [];
        let departments: BackendDepartmentOption[] = [];

        const context = await fetchCreateContext();
        roles = context.roles || [];
        departments = context.departments || [];

        if (id && !employee) {
          const employees = await fetchEmployeesFromApi();
          employee = employees.find((item) => item.userId === id);

          if (!employee) {
            try {
              const details = await fetchEmployeeDetails(id);
              employee = detailsToViewModel(details);
              roles = details.roles || roles;
              departments = details.departments || departments;
            } catch (error) {
              console.error("Ошибка загрузки карточки сотрудника:", error);
            }
          }
        }

        if (!employee) {
          navigate("/employees");
          return;
        }

        setRoleOptions(roles.filter((role) => role.isActive !== false || role.roleId === employee?.roleId));
        setDepartmentOptions(departments.filter((department) => department.isActive !== false || department.departmentId === employee?.departmentId));
        setCurrentEmployee(employee);
        setFormData({
          lastName: employee.lastName || "",
          firstName: employee.firstName || "",
          patronymic: employee.middleName || "",
          roleId: employee.roleId || "",
          departmentId: employee.departmentId || "",
          login: employee.login || "",
          password: "",
        });
      } catch (error) {
        console.error("Ошибка загрузки данных сотрудника:", error);
        window.alert(error instanceof Error ? error.message : "Не удалось загрузить сотрудника");
        navigate("/employees");
      } finally {
        setIsLoading(false);
      }
    };

    loadEmployeeData();
  }, [id, location.state, navigate]);

  const selectedRoleName = useMemo(() => roleOptions.find((role) => role.roleId === formData.roleId)?.name || currentEmployee?.role || "—", [roleOptions, formData.roleId, currentEmployee]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    if (errors[name as keyof FormErrors]) {
      setErrors((prev) => ({ ...prev, [name]: false }));
    }
  };

  const validateForm = () => {
    const newErrors: FormErrors = {
      lastName: !formData.lastName.trim(),
      firstName: !formData.firstName.trim(),
      roleId: !formData.roleId.trim(),
      departmentId: !formData.departmentId.trim(),
      login: !formData.login.trim(),
      password: false,
    };

    setErrors(newErrors);
    return !Object.values(newErrors).some(Boolean);
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (!validateForm() || !currentEmployee) {
      setShowValidationModal(true);
      return;
    }

    try {
      setIsSubmitting(true);
      await updateEmployee(currentEmployee.userId, {
        updatedByUserId: getCurrentUserId(),
        lastName: formData.lastName.trim(),
        firstName: formData.firstName.trim(),
        middleName: formData.patronymic.trim(),
        roleId: formData.roleId,
        departmentId: formData.departmentId,
        login: formData.login.trim(),
        ...(formData.password.trim() ? { password: formData.password.trim() } : {}),
      });

      navigate("/employees", { state: { refresh: Date.now() } });
    } catch (error) {
      console.error("Ошибка сохранения сотрудника:", error);
      window.alert(error instanceof Error ? error.message : "Ошибка при сохранении данных");
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return <div className="employee-edit__loading">Загрузка...</div>;
  }

  return (
    <>
      <div className="employee-form-page employee-form-page--edit">
        <div className="employee-form-page__shell">
          <div className="employee-form-page__header">
            <div className="employee-form-page__header-main">
              <button className="employee-form-page__back" type="button" onClick={() => navigate("/employees")}>
                <SvgIcon name="back" />
                <span>К списку сотрудников</span>
              </button>
              <h1 className="employee-form-page__title">Редактирование сотрудника</h1>
              <p className="employee-form-page__subtitle">
                Изменения отправляются в backend через <code>PATCH /api/employees/{currentEmployee?.userId}</code>.
              </p>
            </div>

            <div className="employee-form-page__summary">
              <div className="employee-summary-card">
                <span className="employee-summary-card__label">Логин</span>
                <strong className="employee-summary-card__value">{formData.login || "—"}</strong>
              </div>
              <div className="employee-summary-card">
                <span className="employee-summary-card__label">Роль</span>
                <strong className="employee-summary-card__value">{selectedRoleName}</strong>
              </div>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="employee-form-page__form">
            <div className="employee-form-sections">
              <section className="employee-form-section">
                <div className="employee-form-section__header">
                  <h2 className="employee-form-section__title">Личные данные</h2>
                  <p className="employee-form-section__text">Проверьте, как имя сотрудника будет отображаться в таблице и карточках.</p>
                </div>

                <div className="employee-form-grid">
                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Фамилия <span>*</span></label>
                    <input className={`ui-input ${errors.lastName ? "error" : ""}`} name="lastName" value={formData.lastName} onChange={handleChange} placeholder="Введите фамилию" />
                  </div>

                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Имя <span>*</span></label>
                    <input className={`ui-input ${errors.firstName ? "error" : ""}`} name="firstName" value={formData.firstName} onChange={handleChange} placeholder="Введите имя" />
                  </div>

                  <div className="employee-edit-form__group employee-form-grid__full">
                    <label className="employee-edit-form__label">Отчество</label>
                    <input className="ui-input" name="patronymic" value={formData.patronymic} onChange={handleChange} placeholder="Введите отчество" />
                  </div>
                </div>
              </section>

              <section className="employee-form-section">
                <div className="employee-form-section__header">
                  <h2 className="employee-form-section__title">Доступ и параметры учётной записи</h2>
                  <p className="employee-form-section__text">Роль, подразделение и логин отправляются в backend.</p>
                </div>

                <div className="employee-form-grid">
                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Роль <span>*</span></label>
                    <div className="ui-select-wrap">
                      <select className={`ui-select ${errors.roleId ? "error" : ""}`} name="roleId" value={formData.roleId} onChange={handleChange}>
                        <option value="">Выберите роль</option>
                        {roleOptions.map((role) => <option key={role.roleId} value={role.roleId}>{role.name}</option>)}
                      </select>
                      <span className="ui-select-wrap__icon"><SvgIcon name="chevron-down" /></span>
                    </div>
                  </div>

                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Подразделение <span>*</span></label>
                    <div className="ui-select-wrap">
                      <select className={`ui-select ${errors.departmentId ? "error" : ""}`} name="departmentId" value={formData.departmentId} onChange={handleChange}>
                        <option value="">Выберите подразделение</option>
                        {departmentOptions.map((dept) => <option key={dept.departmentId} value={dept.departmentId}>{dept.name}</option>)}
                      </select>
                      <span className="ui-select-wrap__icon"><SvgIcon name="chevron-down" /></span>
                    </div>
                  </div>

                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Логин <span>*</span></label>
                    <input className={`ui-input ${errors.login ? "error" : ""}`} name="login" value={formData.login} onChange={handleChange} placeholder="Введите логин" />
                  </div>

                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Новый пароль</label>
                    <input className="ui-input" name="password" type="password" value={formData.password} onChange={handleChange} placeholder="Оставьте пустым, если менять не нужно" />
                    <p className="employee-edit-form__hint">Если поле пустое, пароль не отправляется в backend.</p>
                  </div>
                </div>
              </section>
            </div>

            <div className="employee-form-page__footer">
              <button className="btn btn--ghost" type="button" onClick={() => navigate("/employees")} disabled={isSubmitting}>Отмена</button>
              <button className="btn btn--primary" type="submit" disabled={isSubmitting}>
                <SvgIcon name="save" />
                <span>{isSubmitting ? "Сохранение..." : "Сохранить изменения"}</span>
              </button>
            </div>
          </form>
        </div>
      </div>

      {/* Модальное окно для оповещения о необходимости заполнить все поля */}
      <AppModal
        open={showValidationModal}
        title=""
        description="Пожалуйста, заполните все обязательные поля."
        onClose={() => setShowValidationModal(false)}
        bodyAlign="center"
        actions={
          <button type="button" className="btn btn--primary" onClick={() => setShowValidationModal(false)}>
            Понятно
          </button>
        }
      />
    </>
  );
}