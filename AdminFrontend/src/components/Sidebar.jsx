import React from "react";
import {
  LayoutDashboard,
  Trophy,
  Newspaper,
  Users,
  LogOut,
  RefreshCw,
} from "lucide-react";
import { useAuth } from "../context/AuthContext";

export default function Sidebar({
  activeTab,
  setActiveTab,
  counts,
  onRefresh,
  refreshing,
}) {
  const { admin, logout } = useAuth();

  const navItems = [
    { id: "overview", label: "Overview", icon: LayoutDashboard, count: null },
    {
      id: "predictions",
      label: "Predictions",
      icon: Trophy,
      count: counts.predictions,
    },
    { id: "blogs", label: "Blogs & News", icon: Newspaper, count: counts.blogs },
    {
      id: "users",
      label: "Users & Roles",
      icon: Users,
      count: counts.users,
    },
  ];

  const initial = (admin?.username || admin?.email || "A")
    .charAt(0)
    .toUpperCase();

  return (
    <aside className="sidebar" aria-label="Admin navigation">
      <div>
        <div className="sidebar-brand">
          <div className="brand">
            <span className="brand-badge">B2</span>
            <span>WIN</span>
          </div>
          <span className="sidebar-tag">ADMIN</span>
        </div>

        <nav className="sidebar-nav">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setActiveTab(item.id)}
                className={`nav-item ${isActive ? "active" : ""}`}
                aria-current={isActive ? "page" : undefined}
              >
                <span className="nav-item-left">
                  <Icon size={18} />
                  <span>{item.label}</span>
                </span>
                {item.count !== null && (
                  <span className="count-pill">{item.count}</span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      <div className="sidebar-footer">
        <button
          type="button"
          onClick={onRefresh}
          disabled={refreshing}
          className="btn btn-ghost btn-block btn-sm"
        >
          <RefreshCw size={14} className={refreshing ? "spin" : ""} />
          <span>{refreshing ? "Syncing..." : "Sync Data"}</span>
        </button>

        <div className="admin-profile">
          <div className="admin-avatar">{initial}</div>
          <div className="admin-info">
            <strong>{admin?.username || "Admin"}</strong>
            <span>{admin?.email}</span>
          </div>
        </div>

        <button
          type="button"
          onClick={logout}
          className="btn btn-danger-outline btn-block btn-sm"
        >
          <LogOut size={15} />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>
  );
}

