import React, { useState } from "react";
import { Search, Shield, ShieldOff } from "lucide-react";
import { apiRequest } from "../services/api";
import { useAuth } from "../context/AuthContext";

export default function UsersTab({ users, onReload, showToast }) {
  const { admin } = useAuth();
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [updatingId, setUpdatingId] = useState(null);

  const filtered = users.filter((u) => {
    const roleMatch =
      roleFilter === "all" ||
      (roleFilter === "admin" && u.isAdmin) ||
      (roleFilter === "user" && !u.isAdmin);
    const q = search.toLowerCase();
    const searchMatch =
      !q ||
      (u.username || "").toLowerCase().includes(q) ||
      (u.email || "").toLowerCase().includes(q);
    return roleMatch && searchMatch;
  });

  async function handleRoleToggle(user) {
    const nextAdmin = !user.isAdmin;
    setUpdatingId(user.id);
    try {
      const res = await apiRequest(`/users/${user.id}/role`, {
        method: "PATCH",
        body: JSON.stringify({ isAdmin: nextAdmin }),
      });
      showToast(res.message || "User role updated");
      await onReload();
    } catch (err) {
      showToast(err.message || "Failed to update user role", true);
    } finally {
      setUpdatingId(null);
    }
  }

  return (
    <div className="tab-container">
      <div className="panel-header">
        <div>
          <h2>Users &amp; Role Management</h2>
          <p className="panel-subtitle">
            Manage all {users.length} Supabase user profiles and control
            administrator access.
          </p>
        </div>

        <div className="panel-actions">
          <div className="search-box">
            <Search size={16} className="search-icon" />
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search username or email..."
              aria-label="Search users"
            />
          </div>

          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="select-input"
            aria-label="Filter by role"
          >
            <option value="all">All Roles ({users.length})</option>
            <option value="admin">
              Admins ({users.filter((u) => u.isAdmin).length})
            </option>
            <option value="user">
              Regular Users ({users.filter((u) => !u.isAdmin).length})
            </option>
          </select>
        </div>
      </div>

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Username</th>
              <th>Email</th>
              <th>Role</th>
              <th>Joined</th>
              <th className="text-right">Access Control</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={5} className="empty-cell">
                  No users match your filter.
                </td>
              </tr>
            ) : (
              filtered.map((u) => {
                const isSelf = admin?.id === u.id;
                const isBusy = updatingId === u.id;

                return (
                  <tr key={u.id}>
                    <td>
                      <strong>{u.username}</strong>
                    </td>
                    <td>{u.email}</td>
                    <td>
                      <span
                        className={`badge ${
                          u.isAdmin ? "badge-won" : "badge-neutral"
                        }`}
                      >
                        {u.isAdmin ? "Admin" : "User"}
                      </span>
                    </td>
                    <td>
                      {u.createdAt
                        ? new Date(u.createdAt).toLocaleDateString(undefined, {
                            year: "numeric",
                            month: "short",
                            day: "numeric",
                          })
                        : "-"}
                    </td>
                    <td className="text-right">
                      {isSelf ? (
                        <span className="cell-sub">Current Admin Session</span>
                      ) : (
                        <button
                          type="button"
                          disabled={isBusy}
                          onClick={() => handleRoleToggle(u)}
                          className={`btn btn-sm ${
                            u.isAdmin
                              ? "btn-danger-outline"
                              : "btn-emerald-outline"
                          }`}
                        >
                          {u.isAdmin ? (
                            <>
                              <ShieldOff size={14} />
                              <span>
                                {isBusy ? "Updating..." : "Revoke Admin"}
                              </span>
                            </>
                          ) : (
                            <>
                              <Shield size={14} />
                              <span>
                                {isBusy ? "Updating..." : "Make Admin"}
                              </span>
                            </>
                          )}
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

