import {
  Navigate,
  Outlet,
  Meta,
  Links,
  Scripts,
  ScrollRestoration,
  useLocation
} from "react-router";
import { useEffect, useMemo, useState } from "react";

import { Sidebar } from "./components/sidebar";
import { canAccessPath, getFirstAllowedPath } from "~/lib/access-control";
import { AUTH_EVENT_NAME, getStoredAuthUser, type AuthUser } from "~/lib/auth";
import EmployeesPage from "./routes/employees";
import "./app.css";

export default function AppRoot() {
  const location = useLocation();
  const isLoginPage = location.pathname === "/login";
  const isEmployeeModalRoute = location.pathname === "/employees-modal" || location.pathname.startsWith("/employees/edit/");
  const [isAuthResolved, setIsAuthResolved] = useState(false);
  const [authUser, setAuthUser] = useState<AuthUser | null>(null);

  useEffect(() => {
    const syncAuthState = () => {
      setAuthUser(getStoredAuthUser());
      setIsAuthResolved(true);
    };

    syncAuthState();
    window.addEventListener(AUTH_EVENT_NAME, syncAuthState);
    window.addEventListener("storage", syncAuthState);

    return () => {
      window.removeEventListener(AUTH_EVENT_NAME, syncAuthState);
      window.removeEventListener("storage", syncAuthState);
    };
  }, []);

  const isAuthenticated = Boolean(authUser);
  const canOpenCurrentPage = useMemo(
    () => canAccessPath(location.pathname, authUser),
    [authUser, location.pathname]
  );
  const firstAllowedPath = useMemo(() => getFirstAllowedPath(authUser), [authUser]);

  let content: React.ReactNode;

  if (isLoginPage) {
    content = <Outlet />;
  } else if (!isAuthResolved) {
    content = <div style={{ minHeight: "100vh", background: "#f6f8fb" }} />;
  } else if (!isAuthenticated) {
    content = <Navigate to="/login" replace />;
  } else if (!canOpenCurrentPage) {
    content = firstAllowedPath ? (
      <Navigate to={firstAllowedPath} replace />
    ) : (
      <div className="app-layout">
        <Sidebar />

        <main className="content-area">
          <div className="content-shell">
            <section className="ui-card">
              <div className="ui-empty">Нет доступных страниц для вашей роли.</div>
            </section>
          </div>
        </main>
      </div>
    );
  } else {
    content = (
      <div className="app-layout">
        <Sidebar />

        <main className="content-area">
          <div className="content-shell">
            {isEmployeeModalRoute ? <EmployeesPage /> : <Outlet />}
          </div>
          {isEmployeeModalRoute ? <Outlet /> : null}
        </main>
      </div>
    );
  }

  return (
    <html lang="ru">
      <head>
        <meta charSet="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
      </head>

      <body>
        {content}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}
