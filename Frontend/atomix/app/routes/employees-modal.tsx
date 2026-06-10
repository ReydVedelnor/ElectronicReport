import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router";
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

type EmployeeCreateContextResponse = {
  currentUserId?: string;
  rootDepartmentId?: string;
  rootDepartmentName?: string;
  departments?: BackendDepartmentOption[];
  roles?: BackendRoleOption[];
};

type CreateEmployeeResponse = {
  userId?: string;
  fullName?: string;
  login?: string;
  generatedPassword?: string;
  message?: string;
};

function getCurrentUserId(): string {
  const authUser = getStoredAuthUser();
  const userId = authUser?.userId;

  if (!userId) {
    throw new Error("Не найден userId в localStorage");
  }

  return userId;
}

async function fetchCreateContext(): Promise<EmployeeCreateContextResponse> {
  const params = new URLSearchParams({ userId: getCurrentUserId() });
  const response = await fetch(`${getApiBaseUrl()}/api/employees/create-context?${params.toString()}`);

  if (!response.ok) {
    throw new Error(`Ошибка загрузки данных формы: ${response.status}`);
  }

  return response.json();
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

async function createEmployee(payload: {
  createdByUserId: string;
  lastName: string;
  firstName: string;
  middleName: string;
  roleId: string;
  departmentId: string;
  login: string;
}): Promise<CreateEmployeeResponse> {
  const response = await fetch(`${getApiBaseUrl()}/api/employees/create`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const message = await readBackendError(response);
    throw new Error(message || `Ошибка создания сотрудника: ${response.status}`);
  }

  const text = await response.text().catch(() => "");
  return text ? JSON.parse(text) : {};
}

export default function EmployeeCreatePage() {
  const navigate = useNavigate();

  const [roleOptions, setRoleOptions] = useState<BackendRoleOption[]>([]);
  const [departmentOptions, setDepartmentOptions] = useState<BackendDepartmentOption[]>([]);
  const [isLoadingContext, setIsLoadingContext] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showValidationModal, setShowValidationModal] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [generatedPassword, setGeneratedPassword] = useState("");
  
  const [formData, setFormData] = useState({
    lastName: "",
    firstName: "",
    patronymic: "",
    roleId: "",
    departmentId: "",
    login: "",
  });

  const [errors, setErrors] = useState({
    lastName: false,
    firstName: false,
    roleId: false,
    departmentId: false,
    login: false,
  });

  useEffect(() => {
    const loadContext = async () => {
      try {
        const context = await fetchCreateContext();
        setRoleOptions((context.roles || []).filter((role) => role.isActive !== false));
        setDepartmentOptions((context.departments || []).filter((department) => department.isActive !== false));
      } catch (error) {
        console.error("Ошибка загрузки данных формы сотрудника:", error);
        window.alert(error instanceof Error ? error.message : "Не удалось загрузить данные формы");
      } finally {
        setIsLoadingContext(false);
      }
    };

    loadContext();
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    if (errors[name as keyof typeof errors]) {
      setErrors((prev) => ({ ...prev, [name]: false }));
    }
  };

  const loginPreview = useMemo(() => {
    if (formData.login.trim()) return formData.login.trim();
    const source = formData.lastName.trim() || "user";
    return source.toLowerCase().replace(/\s+/g, "_");
  }, [formData.login, formData.lastName]);

  const handlePasswordModalClose = () => {
    setShowPasswordModal(false);
    setGeneratedPassword("");
    navigate("/employees", { state: { refresh: Date.now() } });
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    const newErrors = {
      lastName: !formData.lastName.trim(),
      firstName: !formData.firstName.trim(),
      roleId: !formData.roleId.trim(),
      departmentId: !formData.departmentId.trim(),
      login: !loginPreview.trim(),
    };

    setErrors(newErrors);

    if (Object.values(newErrors).some(Boolean)) {
      setShowValidationModal(true);
      return;
    }

    try {
      setIsSubmitting(true);
      const result = await createEmployee({
        createdByUserId: getCurrentUserId(),
        lastName: formData.lastName.trim(),
        firstName: formData.firstName.trim(),
        middleName: formData.patronymic.trim(),
        roleId: formData.roleId,
        departmentId: formData.departmentId,
        login: loginPreview.trim(),
      });

      if (result.generatedPassword) {
        setGeneratedPassword(result.generatedPassword);
        setShowPasswordModal(true);
      } else {
        navigate("/employees", { state: { refresh: Date.now() } });
      }
    } catch (error) {
      console.error("Ошибка создания сотрудника:", error);
      window.alert(error instanceof Error ? error.message : "Ошибка при создании сотрудника");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <>
      <div className="employee-form-page employee-form-page--create">
        <div className="employee-form-page__shell">
          <div className="employee-form-page__header">
            <div className="employee-form-page__header-main">
              <button className="employee-form-page__back" type="button" onClick={() => navigate("/employees")}>
                <SvgIcon name="back" />
                <span>К списку сотрудников</span>
              </button>
              <h1 className="employee-form-page__title">Добавление сотрудника</h1>
              <p className="employee-form-page__subtitle">
                Заполните данные сотрудника. Роли и подразделения загружаются из backend.
              </p>
            </div>

            <div className="employee-form-page__summary">
              <div className="employee-summary-card">
                <span className="employee-summary-card__label">Статус</span>
                <strong className="employee-summary-card__value">Активен после создания</strong>
              </div>
              <div className="employee-summary-card">
                <span className="employee-summary-card__label">Логин</span>
                <strong className="employee-summary-card__value">{loginPreview || "user"}</strong>
              </div>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="employee-form-page__form">
            <div className="employee-form-sections">
              <section className="employee-form-section">
                <div className="employee-form-section__header">
                  <h2 className="employee-form-section__title">Личные данные</h2>
                  <p className="employee-form-section__text">Укажите ФИО сотрудника так, как оно должно отображаться в таблице.</p>
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
                    <p className="employee-edit-form__hint">Поле необязательное. Если отчества нет, оставьте его пустым.</p>
                  </div>
                </div>
              </section>

              <section className="employee-form-section">
                <div className="employee-form-section__header">
                  <h2 className="employee-form-section__title">Доступ и подразделение</h2>
                  <p className="employee-form-section__text">Данные выбираются из backend endpoint <code>/api/employees/create-context</code>.</p>
                </div>

                <div className="employee-form-grid">
                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Роль доступа <span>*</span></label>
                    <div className="ui-select-wrap">
                      <select className={`ui-select ${errors.roleId ? "error" : ""}`} name="roleId" value={formData.roleId} onChange={handleChange} disabled={isLoadingContext}>
                        <option value="">Выберите роль</option>
                        {roleOptions.map((role) => <option key={role.roleId} value={role.roleId}>{role.name}</option>)}
                      </select>
                      <span className="ui-select-wrap__icon"><SvgIcon name="chevron-down" /></span>
                    </div>
                  </div>

                  <div className="employee-edit-form__group">
                    <label className="employee-edit-form__label">Подразделение <span>*</span></label>
                    <div className="ui-select-wrap">
                      <select className={`ui-select ${errors.departmentId ? "error" : ""}`} name="departmentId" value={formData.departmentId} onChange={handleChange} disabled={isLoadingContext}>
                        <option value="">Выберите подразделение</option>
                        {departmentOptions.map((dept) => <option key={dept.departmentId} value={dept.departmentId}>{dept.name}</option>)}
                      </select>
                      <span className="ui-select-wrap__icon"><SvgIcon name="chevron-down" /></span>
                    </div>
                  </div>

                  <div className="employee-edit-form__group employee-form-grid__full">
                    <label className="employee-edit-form__label">Логин <span>*</span></label>
                    <input className={`ui-input ${errors.login ? "error" : ""}`} name="login" value={formData.login} onChange={handleChange} placeholder={loginPreview} />
                  </div>
                </div>
              </section>
            </div>

            <div className="employee-form-page__footer">
              <button className="btn btn--ghost" type="button" onClick={() => navigate("/employees")} disabled={isSubmitting}>Отмена</button>
              <button className="btn btn--primary" type="submit" disabled={isSubmitting || isLoadingContext}>
                <SvgIcon name="save" />
                <span>{isSubmitting ? "Сохранение..." : "Добавить сотрудника"}</span>
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

      {/* Модальное окно с временным паролем */}
      <AppModal
        open={showPasswordModal}
        title="Сотрудник создан"
        description={`Временный пароль: ${generatedPassword}`}
        onClose={handlePasswordModalClose}
        bodyAlign="center"
        actions={
          <button type="button" className="btn btn--primary" onClick={handlePasswordModalClose}>
            ОК
          </button>
        }
      />
    </>
  );
}