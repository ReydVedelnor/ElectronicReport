import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { getApiBaseUrl, getStoredAuthUser, saveAuthUser } from "~/lib/auth";

type LoginModuleResponse = {
  slug?: string;
  displayName?: string;
};

type LoginResponse = {
  userId: string;
  login: string;
  fullName?: string;
  roleId?: string;
  roleName?: string;
  modules?: LoginModuleResponse[];
  message?: string;
};

type ErrorResponse = {
  message?: string;
  error?: string;
};

export default function Login() {
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  useEffect(() => {
    if (getStoredAuthUser()) {
      navigate("/", { replace: true });
    }
  }, [navigate]);

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setErrorMessage("");

    const form = e.target as HTMLFormElement;
    const formData = new FormData(form);

    const login = String(formData.get("login") ?? "").trim();
    const password = String(formData.get("password") ?? "");

    if (!login || !password) {
      setErrorMessage("Введите логин и пароль.");
      return;
    }

    setIsSubmitting(true);

    try {
      const response = await fetch(`${getApiBaseUrl()}/api/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ login, password })
      });

      let payload: LoginResponse | ErrorResponse | null = null;
      try {
        payload = (await response.json()) as LoginResponse | ErrorResponse;
      } catch {
        payload = null;
      }

      if (!response.ok) {
        const backendMessage = payload && "message" in payload ? payload.message : "";
        throw new Error(backendMessage || "Не удалось выполнить вход.");
      }

      const data = payload as LoginResponse;
      saveAuthUser({
        userId: data.userId,
        login: data.login,
        fullName: data.fullName?.trim() || data.login,
        roleId: data.roleId?.trim() || undefined,
        roleName: data.roleName?.trim() || undefined,
        modules: Array.isArray(data.modules)
          ? data.modules.map((moduleItem) => String(moduleItem?.slug ?? "").trim()).filter(Boolean)
          : undefined
      });

      navigate("/", { replace: true });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Ошибка сети. Проверьте соединение с сервером.";
      setErrorMessage(message || "Не удалось выполнить вход.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="login-wrapper">
      <div className="login-card">
        <div className="login-logo-wrap">
          <img src="/logo.svg" alt="Логотип" />
        </div>

        <div className="login-title">
          <div className="title-green">ГРИНАТОМ</div>
          <div className="title-blue">РОСАТОМ</div>
        </div>

        <form className="login-form" onSubmit={handleLogin}>
          <div className="login-field ui-field">
            <label className="ui-field__label">Логин</label>
            <img src="/icons/user.svg" className="login-field__icon" alt="" />
            <input className="ui-input" name="login" placeholder="Введите логин" autoComplete="username" />
          </div>

          <div className="login-field ui-field">
            <label className="ui-field__label">Пароль</label>
            <img src="/icons/lock.svg" className="login-field__icon" alt="" />
            <input
              className="ui-input"
              type="password"
              name="password"
              placeholder="Введите пароль"
              autoComplete="current-password"
            />
          </div>

          {errorMessage ? <div className="login-error">{errorMessage}</div> : null}

          <button type="submit" className="btn btn--primary login-button" disabled={isSubmitting}>
            <img src="/icons/sign.svg" className="btn-icon" alt="" />
            {isSubmitting ? "Вход..." : "Войти в систему"}
          </button>
        </form>

        <div className="login-footer">Система производственного учета ГРИНАТОМ</div>
      </div>
    </div>
  );
}
