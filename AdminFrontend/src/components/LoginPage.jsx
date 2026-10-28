import React, { useState } from "react";
import { ShieldCheck, Lock, Mail, AlertCircle, CheckCircle2 } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import { apiRequest } from "../services/api";

export default function LoginPage() {
  const { login, loginWithGoogle, oauthError } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [infoMessage, setInfoMessage] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    setInfoMessage("");
    setSubmitting(true);

    try {
      await login(email.trim(), password);
    } catch (err) {
      setError(err.message || "Failed to sign in");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleGoogleClick() {
    setError("");
    setInfoMessage("");
    try {
      await loginWithGoogle();
    } catch (err) {
      setError(err.message || "Could not start Google Sign-In");
    }
  }

  async function handleForgotPassword() {
    if (!email.trim()) {
      setError("Enter your Admin Email above first, then click Forgot Password.");
      return;
    }
    setError("");
    setInfoMessage("");
    try {
      const res = await apiRequest("/users/forgot-password", {
        method: "POST",
        body: JSON.stringify({ email: email.trim() }),
      });
      setInfoMessage(
        res.message || "Password reset instructions sent to your email."
      );
    } catch (err) {
      setError(err.message || "Failed to send password reset email");
    }
  }

  const displayError = error || oauthError;

  return (
    <main className="auth-screen">
      <div className="auth-card">
        <div className="auth-header">
          <div className="brand-row">
            <span className="brand">
              <span className="brand-badge">B2</span>
              <span>WIN</span>
            </span>
            <span className="admin-pill">
              <ShieldCheck size={13} />
              SUPABASE AUTH
            </span>
          </div>
          <h1>Admin Control Center</h1>
          <p>
            Sign in with your administrator credentials or Google account to
            manage predictions, blogs, and user roles.
          </p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form">
          <div className="form-group">
            <label htmlFor="admin-email">Admin Email</label>
            <div className="input-with-icon">
              <Mail size={17} className="input-icon" />
              <input
                id="admin-email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@b2win.com"
                autoComplete="email"
              />
            </div>
          </div>

          <div className="form-group">
            <div style={{ display: "flex", justifyContent: "space-between" }}>
              <label htmlFor="admin-password">Password</label>
              <button
                type="button"
                onClick={handleForgotPassword}
                className="btn-link"
                style={{ fontSize: "0.78rem" }}
              >
                Forgot password?
              </button>
            </div>
            <div className="input-with-icon">
              <Lock size={17} className="input-icon" />
              <input
                id="admin-password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete="current-password"
              />
            </div>
          </div>

          {displayError && (
            <div className="alert-error" role="alert">
              <AlertCircle size={16} />
              <span>{displayError}</span>
            </div>
          )}

          {infoMessage && (
            <div
              className="alert-error"
              style={{
                background: "rgba(16, 185, 129, 0.14)",
                borderColor: "rgba(16, 185, 129, 0.35)",
                color: "#6ee7b7",
              }}
              role="status"
            >
              <CheckCircle2 size={16} />
              <span>{infoMessage}</span>
            </div>
          )}

          <button
            type="submit"
            disabled={submitting}
            className="btn btn-primary btn-block"
          >
            {submitting ? "Authenticating..." : "Sign In with Email"}
          </button>

          <button
            type="button"
            onClick={handleGoogleClick}
            className="btn btn-ghost btn-block"
          >
            <span>Continue with Google (Supabase OAuth)</span>
          </button>
        </form>
      </div>
    </main>
  );
}
