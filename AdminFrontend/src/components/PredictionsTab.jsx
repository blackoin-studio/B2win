import React, { useState } from "react";
import { Plus, Search, Edit2, Trash2, X, Sparkles } from "lucide-react";
import { apiRequest, resolveImageUrl } from "../services/api";

const EMPTY_FORM = {
  id: "",
  league: "",
  date: new Date().toISOString().slice(0, 10),
  time: "19:45",
  homeTeam: "",
  awayTeam: "",
  tip: "",
  odds: "1.80",
  score: "-",
  status: "pending",
};

export default function PredictionsTab({ predictions, onReload, showToast }) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [aiPrompt, setAiPrompt] = useState("");
  const [aiLoading, setAiLoading] = useState(false);
  const [aiRationale, setAiRationale] = useState("");
  const [form, setForm] = useState(EMPTY_FORM);
  const [files, setFiles] = useState({
    leagueLogo: null,
    homeLogo: null,
    awayLogo: null,
  });

  const filtered = predictions.filter((p) => {
    const statusMatch =
      statusFilter === "all" ||
      (p.status || "pending").toLowerCase() === statusFilter;
    const q = search.toLowerCase();
    const searchMatch =
      !q ||
      (p.homeTeam || "").toLowerCase().includes(q) ||
      (p.awayTeam || "").toLowerCase().includes(q) ||
      (p.league || "").toLowerCase().includes(q) ||
      (p.tip || "").toLowerCase().includes(q);
    return statusMatch && searchMatch;
  });

  function openCreate() {
    setForm({
      ...EMPTY_FORM,
      date: new Date().toISOString().slice(0, 10),
    });
    setAiPrompt("");
    setAiRationale("");
    setFiles({ leagueLogo: null, homeLogo: null, awayLogo: null });
    setModalOpen(true);
  }

  async function handleAiAutofill() {
    if (!aiPrompt.trim()) {
      showToast("Enter a fixture first (e.g., Arsenal vs Chelsea 20:00)", true);
      return;
    }
    setAiLoading(true);
    try {
      const res = await apiRequest("/ai/autofill-prediction", {
        method: "POST",
        body: JSON.stringify({ prompt: aiPrompt }),
      });
      if (res?.data) {
        setForm((prev) => ({
          ...prev,
          league: res.data.league || prev.league,
          homeTeam: res.data.homeTeam || prev.homeTeam,
          awayTeam: res.data.awayTeam || prev.awayTeam,
          time: res.data.time || prev.time,
          tip: res.data.tip || prev.tip,
          odds: res.data.odds || prev.odds,
        }));
        setAiRationale(res.data.rationale || "");
        showToast("AI populated fixture & suggested tip!");
      }
    } catch (err) {
      showToast(err.message || "AI auto-fill failed", true);
    } finally {
      setAiLoading(false);
    }
  }

  function openEdit(pred) {
    setForm({
      id: pred.id,
      league: pred.league || "",
      date: pred.date
        ? new Date(pred.date).toISOString().slice(0, 10)
        : new Date().toISOString().slice(0, 10),
      time: pred.time || "00:00",
      homeTeam: pred.homeTeam || "",
      awayTeam: pred.awayTeam || "",
      tip: pred.tip || "",
      odds: pred.odds || "1.00",
      score: pred.score || "-",
      status: (pred.status || "pending").toLowerCase(),
    });
    setFiles({ leagueLogo: null, homeLogo: null, awayLogo: null });
    setModalOpen(true);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSaving(true);
    try {
      const fd = new FormData();
      fd.append("league", form.league);
      fd.append("date", form.date);
      fd.append("time", form.time);
      fd.append("homeTeam", form.homeTeam);
      fd.append("awayTeam", form.awayTeam);
      fd.append("tip", form.tip);
      fd.append("odds", form.odds);
      fd.append("score", form.score || "-");
      fd.append("status", form.status);
      if (files.leagueLogo) fd.append("leagueLogo", files.leagueLogo);
      if (files.homeLogo) fd.append("homeLogo", files.homeLogo);
      if (files.awayLogo) fd.append("awayLogo", files.awayLogo);

      if (!form.id) {
        await apiRequest("/predictions", { method: "POST", body: fd });
        showToast("Prediction created in Supabase Storage & DB!");
      } else {
        await apiRequest(`/predictions/${form.id}`, {
          method: "PUT",
          body: fd,
        });
        showToast("Prediction updated!");
      }
      setModalOpen(false);
      await onReload();
    } catch (err) {
      showToast(err.message || "Failed to save prediction", true);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm("Delete this prediction permanently?")) return;
    try {
      await apiRequest(`/predictions/${id}`, { method: "DELETE" });
      showToast("Prediction deleted");
      await onReload();
    } catch (err) {
      showToast(err.message || "Failed to delete prediction", true);
    }
  }

  return (
    <div className="tab-container">
      <div className="panel-header">
        <div>
          <h2>Match Predictions</h2>
          <p className="panel-subtitle">
            Manage daily football tips, Supabase Storage team logos, scores, and
            statuses.
          </p>
        </div>

        <div className="panel-actions">
          <div className="search-box">
            <Search size={16} className="search-icon" />
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search team, league, tip..."
              aria-label="Search predictions"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="select-input"
            aria-label="Filter by status"
          >
            <option value="all">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="won">Won</option>
            <option value="lost">Lost</option>
            <option value="postponed">Postponed</option>
            <option value="cancelled">Cancelled</option>
          </select>

          <button type="button" onClick={openCreate} className="btn btn-primary">
            <Plus size={16} />
            <span>New Prediction</span>
          </button>
        </div>
      </div>

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Date &amp; Time</th>
              <th>League</th>
              <th>Matchup</th>
              <th>Score</th>
              <th>Tip &amp; Odds</th>
              <th>Status</th>
              <th className="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="empty-cell">
                  No predictions match your search criteria.
                </td>
              </tr>
            ) : (
              filtered.map((p) => {
                const status = (p.status || "pending").toLowerCase();
                const homeLogo = resolveImageUrl(p.homeLogo);
                const awayLogo = resolveImageUrl(p.awayLogo);
                return (
                  <tr key={p.id}>
                    <td>
                      <strong>
                        {p.date
                          ? new Date(p.date).toLocaleDateString(undefined, {
                              month: "short",
                              day: "numeric",
                              year: "numeric",
                            })
                          : "-"}
                      </strong>
                      <div className="cell-sub">{p.time || "00:00"}</div>
                    </td>
                    <td>{p.league}</td>
                    <td>
                      <div className="matchup-cell">
                        {homeLogo && (
                          <img src={homeLogo} alt="" className="mini-logo" />
                        )}
                        <strong>{p.homeTeam}</strong>
                        <span className="vs-tag">vs</span>
                        {awayLogo && (
                          <img src={awayLogo} alt="" className="mini-logo" />
                        )}
                        <strong>{p.awayTeam}</strong>
                      </div>
                    </td>
                    <td>
                      <span className="score-pill">{p.score || "-"}</span>
                    </td>
                    <td>
                      <strong>{p.tip}</strong>{" "}
                      <span className="cell-sub">(@{p.odds})</span>
                    </td>
                    <td>
                      <span className={`badge badge-${status}`}>{status}</span>
                    </td>
                    <td className="text-right">
                      <div className="row-actions">
                        <button
                          type="button"
                          onClick={() => openEdit(p)}
                          className="btn btn-ghost btn-sm"
                          title="Edit prediction"
                        >
                          <Edit2 size={14} />
                          <span>Edit</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDelete(p.id)}
                          className="btn btn-danger-outline btn-sm"
                          title="Delete prediction"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Create / Edit Modal */}
      {modalOpen && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal-dialog">
            <div className="modal-header">
              <h3>{form.id ? "Edit Prediction" : "New Match Prediction"}</h3>
              <button
                type="button"
                onClick={() => setModalOpen(false)}
                className="icon-close-btn"
                aria-label="Close modal"
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="modal-form">
              {/* AI Quick-Fill Fixture Bar */}
              <div
                style={{
                  padding: "0.85rem 1rem",
                  borderRadius: 12,
                  marginBottom: "1rem",
                  background: "rgba(225, 29, 72, 0.09)",
                  border: "1px solid rgba(225, 29, 72, 0.3)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "0.4rem",
                    fontSize: "0.86rem",
                    color: "#fda4af",
                    marginBottom: "0.5rem",
                  }}
                >
                  <Sparkles size={15} />
                  <strong>AI Fixture Auto-Fill &amp; Tip Predictor</strong>
                </div>
                <div style={{ display: "flex", gap: "0.5rem" }}>
                  <input
                    type="text"
                    value={aiPrompt}
                    onChange={(e) => setAiPrompt(e.target.value)}
                    placeholder="Type e.g. Real Madrid vs Barcelona La Liga 21:00"
                    style={{ flex: 1 }}
                  />
                  <button
                    type="button"
                    disabled={aiLoading}
                    onClick={handleAiAutofill}
                    className="btn btn-primary btn-sm"
                  >
                    <Sparkles size={14} />
                    <span>{aiLoading ? "Analyzing..." : "AI Auto-Fill"}</span>
                  </button>
                </div>
                {aiRationale && (
                  <p
                    style={{
                      margin: "0.5rem 0 0",
                      fontSize: "0.8rem",
                      color: "#cbd5e1",
                    }}
                  >
                    {aiRationale}
                  </p>
                )}
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>League *</label>
                  <input
                    type="text"
                    required
                    value={form.league}
                    onChange={(e) =>
                      setForm({ ...form, league: e.target.value })
                    }
                    placeholder="e.g. Premier League"
                  />
                </div>
                <div className="form-group">
                  <label>Match Date *</label>
                  <input
                    type="date"
                    required
                    value={form.date}
                    onChange={(e) => setForm({ ...form, date: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Kick-off Time *</label>
                  <input
                    type="text"
                    required
                    value={form.time}
                    onChange={(e) => setForm({ ...form, time: e.target.value })}
                    placeholder="19:45"
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Home Team *</label>
                  <input
                    type="text"
                    required
                    value={form.homeTeam}
                    onChange={(e) =>
                      setForm({ ...form, homeTeam: e.target.value })
                    }
                    placeholder="e.g. Arsenal"
                  />
                </div>
                <div className="form-group">
                  <label>Away Team *</label>
                  <input
                    type="text"
                    required
                    value={form.awayTeam}
                    onChange={(e) =>
                      setForm({ ...form, awayTeam: e.target.value })
                    }
                    placeholder="e.g. Liverpool"
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Tip *</label>
                  <input
                    type="text"
                    required
                    value={form.tip}
                    onChange={(e) => setForm({ ...form, tip: e.target.value })}
                    placeholder="e.g. Over 2.5 / 1X"
                  />
                </div>
                <div className="form-group">
                  <label>Odds *</label>
                  <input
                    type="text"
                    required
                    value={form.odds}
                    onChange={(e) => setForm({ ...form, odds: e.target.value })}
                    placeholder="1.85"
                  />
                </div>
                <div className="form-group">
                  <label>Score</label>
                  <input
                    type="text"
                    value={form.score}
                    onChange={(e) =>
                      setForm({ ...form, score: e.target.value })
                    }
                    placeholder="- or 2 - 1"
                  />
                </div>
                <div className="form-group">
                  <label>Status *</label>
                  <select
                    value={form.status}
                    onChange={(e) =>
                      setForm({ ...form, status: e.target.value })
                    }
                  >
                    <option value="pending">Pending</option>
                    <option value="won">Won</option>
                    <option value="lost">Lost</option>
                    <option value="postponed">Postponed</option>
                    <option value="cancelled">Cancelled</option>
                  </select>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>League Logo (Supabase Storage)</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) =>
                      setFiles({ ...files, leagueLogo: e.target.files[0] })
                    }
                  />
                </div>
                <div className="form-group">
                  <label>Home Team Logo</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) =>
                      setFiles({ ...files, homeLogo: e.target.files[0] })
                    }
                  />
                </div>
                <div className="form-group">
                  <label>Away Team Logo</label>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) =>
                      setFiles({ ...files, awayLogo: e.target.files[0] })
                    }
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  onClick={() => setModalOpen(false)}
                  className="btn btn-ghost"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="btn btn-primary"
                >
                  {saving ? "Uploading..." : "Save Prediction"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
