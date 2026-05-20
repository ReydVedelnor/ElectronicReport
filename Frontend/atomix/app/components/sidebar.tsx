import { useEffect, useMemo, useState } from "react";
import { NavLink, useNavigate } from "react-router";
import { getAllowedMenuPermissions } from "~/lib/access-control";
import { AUTH_EVENT_NAME, clearAuthSession, getStoredAuthUser, type AuthUser } from "~/lib/auth";

export function Sidebar() {
  const navigate = useNavigate();
  const [user, setUser] = useState<AuthUser | null>(null);

  useEffect(() => {
    const syncUser = () => {
      setUser(getStoredAuthUser());
    };

    syncUser();
    window.addEventListener(AUTH_EVENT_NAME, syncUser);
    window.addEventListener("storage", syncUser);

    return () => {
      window.removeEventListener(AUTH_EVENT_NAME, syncUser);
      window.removeEventListener("storage", syncUser);
    };
  }, []);

  const menuItems = useMemo(() => getAllowedMenuPermissions(user), [user]);
  const userName = user?.fullName || user?.login || "Пользователь";

  const handleLogout = () => {
    clearAuthSession();
    navigate("/login", { replace: true });
  };

  return (
    <aside className="sidebar">
      <div className="sidebar__top">
        <div className="logo">
          <img src="/logo.svg" alt="logo" />
          <div className="logo__text">
            <div className="logo__title">ГРИНАТОМ</div>
            <div className="logo__subtitle">РОСАТОМ</div>
          </div>
        </div>

        <div className="user-card">
          <span className="user-img"><img src="/icons/default_user.svg" alt="img" /></span>
          <span className="user-name">{userName}</span>
        </div>

        <nav className="menu">
          {menuItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === "/"}
              className={({ isActive }) =>
                isActive ? "menu__link menu__link--active" : "menu__link"
              }
            >
              <span className="menu__icon-wrap">
                <img src={item.icon} className="menu__icon" alt="" />
              </span>
              <span className="menu__text">{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </div>

      <div className="sidebar__bottom">
        <button type="button" className="logout-button" onClick={handleLogout}>
          <span className="menu__icon-wrap">
            <img src="/icons/exit.svg" className="menu__icon" alt="" />
          </span>
          <span>Выйти</span>
        </button>
      </div>
    </aside>
  );
}
