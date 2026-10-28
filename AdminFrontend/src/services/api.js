const API_ORIGIN = (import.meta.env.VITE_API_ORIGIN || "").replace(/\/+$/, "");
const API_BASE = `${API_ORIGIN}/api/v1`;

export const TOKEN_KEY = "b2win_admin_token";
export const REFRESH_KEY = "b2win_admin_refresh_token";

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setSessionTokens(token, refreshToken) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  if (refreshToken) localStorage.setItem(REFRESH_KEY, refreshToken);
}

export function clearSessionTokens() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

export function resolveImageUrl(filename) {
  if (!filename || filename.startsWith("no-")) {
    return null;
  }
  if (filename.startsWith("http://") || filename.startsWith("https://")) {
    return filename;
  }
  return `${API_ORIGIN}/public/${encodeURIComponent(filename)}`;
}

export async function apiRequest(endpoint, options = {}) {
  const url = `${API_BASE}${endpoint}`;
  const headers = { ...(options.headers || {}) };
  const token = getToken();

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  if (
    options.body &&
    !(options.body instanceof FormData) &&
    !headers["Content-Type"]
  ) {
    headers["Content-Type"] = "application/json";
  }

  let response = await fetch(url, { ...options, headers });

  // Automatic Supabase Auth token refresh on 401
  const storedRefresh = localStorage.getItem(REFRESH_KEY);
  if (response.status === 401 && storedRefresh && endpoint !== "/users/refresh") {
    const refreshRes = await fetch(`${API_BASE}/users/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken: storedRefresh }),
    });

    if (refreshRes.ok) {
      const refreshData = await refreshRes.json();
      setSessionTokens(refreshData.token, refreshData.refreshToken);
      headers.Authorization = `Bearer ${refreshData.token}`;
      response = await fetch(url, { ...options, headers });
    } else {
      clearSessionTokens();
    }
  }

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const errMsg =
      data.error ||
      data.message ||
      `Request failed with status ${response.status}`;
    throw new Error(errMsg);
  }

  return data;
}

