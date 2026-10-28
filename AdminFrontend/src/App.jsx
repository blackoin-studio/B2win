import React, { useCallback, useEffect, useState } from "react";
import { useAuth } from "./context/AuthContext";
import { apiRequest } from "./services/api";
import LoginPage from "./components/LoginPage";
import Sidebar from "./components/Sidebar";
import OverviewTab from "./components/OverviewTab";
import PredictionsTab from "./components/PredictionsTab";
import BlogsTab from "./components/BlogsTab";
import UsersTab from "./components/UsersTab";

export default function App() {
  const { admin, loading } = useAuth();
  const [activeTab, setActiveTab] = useState("overview");
  const [predictions, setPredictions] = useState([]);
  const [blogs, setBlogs] = useState([]);
  const [users, setUsers] = useState([]);
  const [refreshing, setRefreshing] = useState(false);
  const [toasts, setToasts] = useState([]);

  const showToast = useCallback((message, isError = false) => {
    const id = Date.now() + Math.random();
    setToasts((prev) => [...prev, { id, message, isError }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 3600);
  }, []);

  const loadAllData = useCallback(async () => {
    if (!admin) return;
    setRefreshing(true);
    try {
      const [predsData, blogsData, usersData] = await Promise.all([
        apiRequest("/predictions"),
        apiRequest("/blogs"),
        apiRequest("/users"),
      ]);
      setPredictions(Array.isArray(predsData) ? predsData : []);
      setBlogs(Array.isArray(blogsData) ? blogsData : []);
      setUsers(Array.isArray(usersData?.data) ? usersData.data : []);
    } catch (err) {
      showToast(err.message || "Failed to load dashboard data", true);
    } finally {
      setRefreshing(false);
    }
  }, [admin, showToast]);

  useEffect(() => {
    if (admin) {
      loadAllData();
    }
  }, [admin, loadAllData]);

  async function handleQuickStatusChange(predId, status) {
    try {
      await apiRequest(`/predictions/${predId}`, {
        method: "PUT",
        body: JSON.stringify({ status }),
      });
      showToast(`Prediction marked as ${status.toUpperCase()}`);
      await loadAllData();
    } catch (err) {
      showToast(err.message || "Failed to update status", true);
    }
  }

  if (loading) {
    return (
      <div className="loading-screen">
        <div className="spinner" />
        <p>Verifying Supabase Admin session...</p>
      </div>
    );
  }

  if (!admin) {
    return <LoginPage />;
  }

  return (
    <div className="dashboard-layout">
      {/* Toast Notifications */}
      <div className="toast-container" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast ${t.isError ? "error" : ""}`}>
            {t.message}
          </div>
        ))}
      </div>

      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        counts={{
          predictions: predictions.length,
          blogs: blogs.length,
          users: users.length,
        }}
        onRefresh={loadAllData}
        refreshing={refreshing}
      />

      <main className="workspace">
        {activeTab === "overview" && (
          <OverviewTab
            predictions={predictions}
            blogs={blogs}
            users={users}
            onNavigate={setActiveTab}
            onQuickStatusChange={handleQuickStatusChange}
          />
        )}

        {activeTab === "predictions" && (
          <PredictionsTab
            predictions={predictions}
            onReload={loadAllData}
            showToast={showToast}
          />
        )}

        {activeTab === "blogs" && (
          <BlogsTab
            blogs={blogs}
            onReload={loadAllData}
            showToast={showToast}
          />
        )}

        {activeTab === "users" && (
          <UsersTab
            users={users}
            onReload={loadAllData}
            showToast={showToast}
          />
        )}
      </main>
    </div>
  );
}

