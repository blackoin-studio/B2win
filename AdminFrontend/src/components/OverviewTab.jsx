import React from "react";
import {
  Trophy,
  TrendingUp,
  Newspaper,
  Users,
  CheckCircle2,
  XCircle,
  Clock,
  ArrowRight,
} from "lucide-react";

export default function OverviewTab({
  predictions,
  blogs,
  users,
  onNavigate,
  onQuickStatusChange,
}) {
  const wonCount = predictions.filter((p) => p.status === "won").length;
  const lostCount = predictions.filter((p) => p.status === "lost").length;
  const pendingCount = predictions.filter(
    (p) => !p.status || p.status === "pending"
  ).length;
  const settledCount = wonCount + lostCount;
  const winRate =
    settledCount > 0 ? Math.round((wonCount / settledCount) * 100) : 0;
  const adminCount = users.filter((u) => u.isAdmin).length;

  return (
    <div className="tab-container">
      <div className="panel-header">
        <div>
          <h2>Platform Overview</h2>
          <p className="panel-subtitle">
            Real-time metrics across Supabase predictions, blogs, and registered
            profiles.
          </p>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="kpi-grid">
        <div className="kpi-card">
          <div className="kpi-top">
            <span className="kpi-label">Total Predictions</span>
            <Trophy size={18} className="text-red" />
          </div>
          <strong className="kpi-value">{predictions.length}</strong>
          <span className="kpi-sub">{pendingCount} pending settlement</span>
        </div>

        <div className="kpi-card">
          <div className="kpi-top">
            <span className="kpi-label">Settled Win Rate</span>
            <TrendingUp size={18} className="text-emerald" />
          </div>
          <strong className="kpi-value text-emerald">{winRate}%</strong>
          <span className="kpi-sub">
            {wonCount} won / {lostCount} lost
          </span>
        </div>

        <div className="kpi-card">
          <div className="kpi-top">
            <span className="kpi-label">Published Blogs</span>
            <Newspaper size={18} className="text-amber" />
          </div>
          <strong className="kpi-value">{blogs.length}</strong>
          <span className="kpi-sub">Sports news &amp; guides</span>
        </div>

        <div className="kpi-card">
          <div className="kpi-top">
            <span className="kpi-label">Registered Users</span>
            <Users size={18} className="text-blue" />
          </div>
          <strong className="kpi-value">{users.length}</strong>
          <span className="kpi-sub">{adminCount} active administrators</span>
        </div>
      </div>

      {/* Split Panels */}
      <div className="overview-grid">
        {/* Recent Predictions Quick Settle */}
        <section className="card-panel">
          <div className="card-panel-header">
            <h3>Recent Match Predictions</h3>
            <button
              type="button"
              onClick={() => onNavigate("predictions")}
              className="btn-link"
            >
              Manage All <ArrowRight size={14} />
            </button>
          </div>

          <div className="mini-list">
            {predictions.slice(0, 5).map((p) => (
              <div key={p.id} className="mini-list-item">
                <div>
                  <div className="mini-item-title">
                    {p.homeTeam} vs {p.awayTeam}
                  </div>
                  <div className="mini-item-sub">
                    {p.league} &middot; Tip: <strong>{p.tip}</strong> (@{p.odds})
                  </div>
                </div>

                <div className="quick-status-group">
                  <button
                    type="button"
                    title="Mark Won"
                    onClick={() => onQuickStatusChange(p.id, "won")}
                    className={`status-icon-btn ${
                      p.status === "won" ? "active-won" : ""
                    }`}
                  >
                    <CheckCircle2 size={16} />
                  </button>
                  <button
                    type="button"
                    title="Mark Pending"
                    onClick={() => onQuickStatusChange(p.id, "pending")}
                    className={`status-icon-btn ${
                      p.status === "pending" ? "active-pending" : ""
                    }`}
                  >
                    <Clock size={16} />
                  </button>
                  <button
                    type="button"
                    title="Mark Lost"
                    onClick={() => onQuickStatusChange(p.id, "lost")}
                    className={`status-icon-btn ${
                      p.status === "lost" ? "active-lost" : ""
                    }`}
                  >
                    <XCircle size={16} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Newest Registered Users */}
        <section className="card-panel">
          <div className="card-panel-header">
            <h3>Newest Registered Users</h3>
            <button
              type="button"
              onClick={() => onNavigate("users")}
              className="btn-link"
            >
              View All ({users.length}) <ArrowRight size={14} />
            </button>
          </div>

          <div className="mini-list">
            {users.slice(0, 5).map((u) => (
              <div key={u.id} className="mini-list-item">
                <div>
                  <div className="mini-item-title">{u.username}</div>
                  <div className="mini-item-sub">{u.email}</div>
                </div>
                <span
                  className={`badge ${
                    u.isAdmin ? "badge-won" : "badge-neutral"
                  }`}
                >
                  {u.isAdmin ? "Admin" : "User"}
                </span>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}

