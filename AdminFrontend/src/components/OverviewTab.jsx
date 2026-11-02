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
  Megaphone,
  Sparkles,
} from "lucide-react";

export default function OverviewTab({
  predictions,
  blogs,
  users,
  adSettings,
  aiInsights,
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

        <div
          className="kpi-card"
          onClick={() => onNavigate("ads")}
          style={{ cursor: "pointer" }}
        >
          <div className="kpi-top">
            <span className="kpi-label">Mobile Google Ads</span>
            <Megaphone
              size={18}
              className={adSettings?.adsEnabled ? "text-emerald" : "text-red"}
            />
          </div>
          <strong
            className={`kpi-value ${
              adSettings?.adsEnabled ? "text-emerald" : ""
            }`}
          >
            {adSettings?.adsEnabled ? "ENABLED" : "OFF"}
          </strong>
          <span className="kpi-sub">
            {adSettings?.adsEnabled
              ? adSettings?.testMode
                ? "Test ads active · Click to configure"
                : "Live AdMob units · Click to configure"
              : "Click to turn on AdMob monetization"}
          </span>
        </div>
      </div>

      {/* AI Performance & Strategy Insights Card */}
      {aiInsights && (
        <section
          className="card-panel"
          style={{
            marginBottom: "1.5rem",
            border: "1px solid rgba(225, 29, 72, 0.35)",
            background:
              "linear-gradient(135deg, rgba(225, 29, 72, 0.10), rgba(15, 23, 42, 0.92))",
          }}
        >
          <div className="card-panel-header">
            <h3 style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <Sparkles size={18} className="text-red" />
              <span>B2win AI Performance &amp; Tipster Insights</span>
            </h3>
            <div style={{ display: "flex", gap: "0.5rem", flexWrap: "wrap" }}>
              <span className="badge badge-won">
                Best League: {aiInsights.topLeague?.name} (
                {aiInsights.topLeague?.winRate}%)
              </span>
              <span className="badge badge-pending">
                Best Market: {aiInsights.topMarket?.name} (
                {aiInsights.topMarket?.winRate}%)
              </span>
              <span className="badge badge-neutral">
                Avg Odds: @{aiInsights.averageOdds}
              </span>
            </div>
          </div>

          <div className="mini-list">
            {(aiInsights.recommendations || []).map((rec, idx) => (
              <div key={idx} className="mini-list-item">
                <div className="mini-item-sub" style={{ color: "#e2e8f0" }}>
                  &bull; {rec}
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

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

