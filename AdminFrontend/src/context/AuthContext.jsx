import React, { createContext, useContext, useEffect, useState } from "react";
import {
  apiRequest,
  clearSessionTokens,
  getToken,
  setSessionTokens,
} from "../services/api";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [admin, setAdmin] = useState(null);
  const [loading, setLoading] = useState(true);
  const [oauthError, setOauthError] = useState("");

  useEffect(() => {
    async function initAuth() {
      // 1. Check if returning from Supabase Google OAuth redirect (#access_token=...)
      if (window.location.hash && window.location.hash.includes("access_token=")) {
        const params = new URLSearchParams(window.location.hash.substring(1));
        const accessToken = params.get("access_token");
        const refreshToken = params.get("refresh_token");
        window.history.replaceState(null, "", window.location.pathname);

        if (accessToken) {
          try {
            const data = await apiRequest("/users/oauth/google", {
              method: "POST",
              body: JSON.stringify({ accessToken, refreshToken }),
            });

            if (!data.user?.isAdmin) {
              setOauthError(
                `Google account "${data.user?.email}" does not have Admin privileges. Run: node scripts/make-admin.js ${data.user?.email}`
              );
              setLoading(false);
              return;
            }

            setSessionTokens(data.token, data.refreshToken);
            setAdmin(data.user);
            setLoading(false);
            return;
          } catch (err) {
            setOauthError(err.message || "Google Sign-In failed");
          }
        }
      }

      // 2. Otherwise check stored session token
      const token = getToken();
      if (!token) {
        setLoading(false);
        return;
      }

      try {
        const data = await apiRequest("/users/me");
        if (data?.user?.isAdmin) {
          setAdmin(data.user);
        } else {
          clearSessionTokens();
          setAdmin(null);
        }
      } catch (_) {
        clearSessionTokens();
        setAdmin(null);
      } finally {
        setLoading(false);
      }
    }

    initAuth();
  }, []);

  async function login(email, password) {
    setOauthError("");
    const data = await apiRequest("/users/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });

    if (!data.user?.isAdmin) {
      throw new Error(
        `Account "${email}" does not have Admin privileges. Run: node scripts/make-admin.js ${email}`
      );
    }

    setSessionTokens(data.token, data.refreshToken);
    setAdmin(data.user);
    return data.user;
  }

  async function loginWithGoogle() {
    setOauthError("");
    const redirectTo = window.location.origin;
    const data = await apiRequest(
      `/users/oauth/google?redirectTo=${encodeURIComponent(redirectTo)}`
    );
    if (data?.url) {
      window.location.href = data.url;
    }
  }

  async function logout() {
    try {
      await apiRequest("/users/logout", { method: "POST" });
    } catch (_) {
      // Ignore logout network errors
    } finally {
      clearSessionTokens();
      setAdmin(null);
    }
  }

  return (
    <AuthContext.Provider
      value={{
        admin,
        loading,
        oauthError,
        login,
        loginWithGoogle,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return ctx;
}
