import React, { useEffect, useState } from "react";
import {
  Megaphone,
  Power,
  ShieldAlert,
  Smartphone,
  Sliders,
  Save,
  RotateCcw,
} from "lucide-react";
import { apiRequest } from "../services/api";

const TEST_IDS = {
  androidBannerUnitId: "ca-app-pub-3940256099942544/6300978111",
  iosBannerUnitId: "ca-app-pub-3940256099942544/2934735716",
  androidInterstitialUnitId: "ca-app-pub-3940256099942544/1033173712",
  iosInterstitialUnitId: "ca-app-pub-3940256099942544/4411468910",
};

export default function AdsTab({ adSettings, onReload, showToast }) {
  const [form, setForm] = useState({
    adsEnabled: false,
    testMode: true,
    bannerEnabled: true,
    interstitialEnabled: true,
    showOnHome: true,
    showOnBlog: true,
    interstitialInterval: 3,
    ...TEST_IDS,
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (adSettings) {
      setForm((prev) => ({
        ...prev,
        ...adSettings,
      }));
    }
  }, [adSettings]);

  async function saveSettings(nextPayload, customToast) {
    setSaving(true);
    try {
      const res = await apiRequest("/settings/ads", {
        method: "PUT",
        body: JSON.stringify(nextPayload),
      });
      if (res?.data) {
        setForm((prev) => ({ ...prev, ...res.data }));
      }
      showToast(
        customToast ||
          res?.message ||
          "Google Ads settings updated successfully"
      );
      if (onReload) {
        await onReload();
      }
    } catch (err) {
      showToast(err.message || "Failed to update Google Ads settings", true);
    } finally {
      setSaving(false);
    }
  }

  async function handleMasterToggle() {
    const nextEnabled = !form.adsEnabled;
    const updated = { ...form, adsEnabled: nextEnabled };
    setForm(updated);
    await saveSettings(
      updated,
      nextEnabled
        ? "Google Ads turned ON for all mobile app users"
        : "Google Ads turned OFF across the mobile app"
    );
  }

  async function handleSubmit(e) {
    e.preventDefault();
    await saveSettings(form);
  }

  function handleResetTestIds() {
    setForm((prev) => ({
      ...prev,
      testMode: true,
      ...TEST_IDS,
    }));
    showToast("Populated official Google AdMob test unit IDs");
  }

  return (
    <div className="tab-container">
      <div className="panel-header">
        <div>
          <h2>Google Ads (AdMob) Control Center</h2>
          <p className="panel-subtitle">
            Dynamically toggle Google Mobile Ads on or off in the B2win Flutter
            app and manage AdMob placements &amp; unit IDs in real time.
          </p>
        </div>
      </div>

      {/* Master Global Switch Banner */}
      <section
        className="card-panel"
        style={{
          marginBottom: "1.5rem",
          border: form.adsEnabled
            ? "1px solid rgba(16, 185, 129, 0.45)"
            : "1px solid rgba(255, 255, 255, 0.08)",
          background: form.adsEnabled
            ? "linear-gradient(135deg, rgba(16, 185, 129, 0.12), rgba(15, 23, 42, 0.9))"
            : undefined,
        }}
      >
        <div
          style={{
            display: "flex",
            flexWrap: "wrap",
            alignItems: "center",
            justifyContent: "space-between",
            gap: "1rem",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
            <div
              style={{
                width: 48,
                height: 48,
                borderRadius: 12,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: form.adsEnabled
                  ? "rgba(16, 185, 129, 0.2)"
                  : "rgba(239, 68, 68, 0.15)",
                color: form.adsEnabled ? "#10b981" : "#f87171",
              }}
            >
              <Megaphone size={24} />
            </div>
            <div>
              <div
                style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}
              >
                <h3 style={{ margin: 0 }}>Mobile App Google Ads Status</h3>
                <span
                  className={`badge ${
                    form.adsEnabled ? "badge-won" : "badge-neutral"
                  }`}
                >
                  {form.adsEnabled ? "LIVE / ENABLED" : "DISABLED"}
                </span>
                {form.adsEnabled && form.testMode && (
                  <span className="badge badge-pending">TEST MODE</span>
                )}
              </div>
              <p
                style={{
                  margin: "0.35rem 0 0",
                  fontSize: "0.88rem",
                  color: "#94a3b8",
                }}
              >
                {form.adsEnabled
                  ? "Mobile clients are currently initializing AdMob and rendering enabled ad placements."
                  : "All ads are completely hidden in the mobile app. Turn on when you are ready to monetize."}
              </p>
              {adSettings?.updatedAt && (
                <p
                  style={{
                    margin: "0.25rem 0 0",
                    fontSize: "0.78rem",
                    color: "#64748b",
                  }}
                >
                  Last updated:{" "}
                  {new Date(adSettings.updatedAt).toLocaleString()}
                  {adSettings.updatedBy ? ` by ${adSettings.updatedBy}` : ""}
                </p>
              )}
            </div>
          </div>

          <button
            type="button"
            onClick={handleMasterToggle}
            disabled={saving}
            className={`btn ${
              form.adsEnabled ? "btn-danger-outline" : "btn-primary"
            }`}
            style={{ minWidth: 210, justifyContent: "center" }}
          >
            <Power size={16} />
            <span>
              {saving
                ? "Updating..."
                : form.adsEnabled
                ? "Turn Google Ads OFF"
                : "Turn Google Ads ON"}
            </span>
          </button>
        </div>
      </section>

      <form onSubmit={handleSubmit} className="overview-grid">
        {/* Placement & Behavior Controls */}
        <section className="card-panel">
          <div className="card-panel-header">
            <h3 style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <Sliders size={18} />
              <span>Placements &amp; Delivery Rules</span>
            </h3>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "1rem" }}>
            <label className="mini-list-item" style={{ cursor: "pointer" }}>
              <div>
                <div className="mini-item-title">
                  Use Google Test Mode (Safe Preview)
                </div>
                <div className="mini-item-sub">
                  Uses Google&apos;s sample test ad units so you can test ads on
                  your device/emulator without policy risk.
                </div>
              </div>
              <input
                type="checkbox"
                checked={form.testMode}
                onChange={(e) =>
                  setForm({ ...form, testMode: e.target.checked })
                }
                style={{ width: 20, height: 20, accentColor: "#e11d48" }}
              />
            </label>

            <label className="mini-list-item" style={{ cursor: "pointer" }}>
              <div>
                <div className="mini-item-title">Enable Banner Ads</div>
                <div className="mini-item-sub">
                  Displays a sleek adaptive 320x50 banner in enabled screens.
                </div>
              </div>
              <input
                type="checkbox"
                checked={form.bannerEnabled}
                onChange={(e) =>
                  setForm({ ...form, bannerEnabled: e.target.checked })
                }
                style={{ width: 20, height: 20, accentColor: "#e11d48" }}
              />
            </label>

            <label className="mini-list-item" style={{ cursor: "pointer" }}>
              <div>
                <div className="mini-item-title">
                  Show Banner on Predictions (Home Tab)
                </div>
                <div className="mini-item-sub">
                  Renders a sticky bottom banner on the main match predictions
                  feed.
                </div>
              </div>
              <input
                type="checkbox"
                checked={form.showOnHome}
                onChange={(e) =>
                  setForm({ ...form, showOnHome: e.target.checked })
                }
                style={{ width: 20, height: 20, accentColor: "#e11d48" }}
              />
            </label>

            <label className="mini-list-item" style={{ cursor: "pointer" }}>
              <div>
                <div className="mini-item-title">
                  Show Banner on Blogs &amp; News Tab
                </div>
                <div className="mini-item-sub">
                  Renders a banner on the trending blogs &amp; article reader
                  views.
                </div>
              </div>
              <input
                type="checkbox"
                checked={form.showOnBlog}
                onChange={(e) =>
                  setForm({ ...form, showOnBlog: e.target.checked })
                }
                style={{ width: 20, height: 20, accentColor: "#e11d48" }}
              />
            </label>

            <label className="mini-list-item" style={{ cursor: "pointer" }}>
              <div>
                <div className="mini-item-title">Enable Interstitial Ads</div>
                <div className="mini-item-sub">
                  Full-screen ads shown periodically when opening blog posts.
                </div>
              </div>
              <input
                type="checkbox"
                checked={form.interstitialEnabled}
                onChange={(e) =>
                  setForm({ ...form, interstitialEnabled: e.target.checked })
                }
                style={{ width: 20, height: 20, accentColor: "#e11d48" }}
              />
            </label>

            <div className="form-group" style={{ marginTop: "0.5rem" }}>
              <label htmlFor="interstitialInterval">
                Interstitial Frequency (Every N article opens)
              </label>
              <input
                id="interstitialInterval"
                type="number"
                min={1}
                max={50}
                value={form.interstitialInterval}
                onChange={(e) =>
                  setForm({
                    ...form,
                    interstitialInterval: Number(e.target.value) || 3,
                  })
                }
              />
            </div>
          </div>
        </section>

        {/* AdMob Unit IDs Configuration */}
        <section className="card-panel">
          <div className="card-panel-header">
            <h3 style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
              <Smartphone size={18} />
              <span>AdMob Ad Unit IDs</span>
            </h3>
            <button
              type="button"
              onClick={handleResetTestIds}
              className="btn btn-ghost btn-sm"
            >
              <RotateCcw size={14} />
              <span>Fill Test IDs</span>
            </button>
          </div>

          {form.testMode && (
            <div
              style={{
                display: "flex",
                alignItems: "flex-start",
                gap: "0.6rem",
                padding: "0.75rem 1rem",
                borderRadius: 10,
                background: "rgba(245, 158, 11, 0.12)",
                border: "1px solid rgba(245, 158, 11, 0.3)",
                color: "#fcd34d",
                fontSize: "0.83rem",
                marginBottom: "1rem",
              }}
            >
              <ShieldAlert size={18} style={{ flexShrink: 0, marginTop: 2 }} />
              <span>
                <strong>Test Mode is active.</strong> The mobile app will use
                Google&apos;s official sample Ad Unit IDs regardless of the
                custom IDs below. Uncheck &ldquo;Use Google Test Mode&rdquo;
                when deploying your live AdMob Unit IDs.
              </span>
            </div>
          )}

          <div className="form-grid" style={{ gridTemplateColumns: "1fr" }}>
            <div className="form-group">
              <label htmlFor="androidBannerUnitId">
                Android Banner Ad Unit ID
              </label>
              <input
                id="androidBannerUnitId"
                type="text"
                value={form.androidBannerUnitId}
                onChange={(e) =>
                  setForm({ ...form, androidBannerUnitId: e.target.value })
                }
                placeholder="ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
              />
            </div>

            <div className="form-group">
              <label htmlFor="androidInterstitialUnitId">
                Android Interstitial Ad Unit ID
              </label>
              <input
                id="androidInterstitialUnitId"
                type="text"
                value={form.androidInterstitialUnitId}
                onChange={(e) =>
                  setForm({
                    ...form,
                    androidInterstitialUnitId: e.target.value,
                  })
                }
                placeholder="ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
              />
            </div>

            <div className="form-group">
              <label htmlFor="iosBannerUnitId">iOS Banner Ad Unit ID</label>
              <input
                id="iosBannerUnitId"
                type="text"
                value={form.iosBannerUnitId}
                onChange={(e) =>
                  setForm({ ...form, iosBannerUnitId: e.target.value })
                }
                placeholder="ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
              />
            </div>

            <div className="form-group">
              <label htmlFor="iosInterstitialUnitId">
                iOS Interstitial Ad Unit ID
              </label>
              <input
                id="iosInterstitialUnitId"
                type="text"
                value={form.iosInterstitialUnitId}
                onChange={(e) =>
                  setForm({ ...form, iosInterstitialUnitId: e.target.value })
                }
                placeholder="ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
              />
            </div>
          </div>

          <div
            style={{
              marginTop: "1.25rem",
              display: "flex",
              justifyContent: "flex-end",
            }}
          >
            <button
              type="submit"
              disabled={saving}
              className="btn btn-primary"
            >
              <Save size={16} />
              <span>{saving ? "Saving..." : "Save Ad Configuration"}</span>
            </button>
          </div>
        </section>
      </form>
    </div>
  );
}

