import React, { useState } from "react";
import { Plus, Search, Edit2, Trash2, X } from "lucide-react";
import { apiRequest, resolveImageUrl } from "../services/api";

export default function BlogsTab({ blogs, onReload, showToast }) {
  const [search, setSearch] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ id: "", title: "", description: "" });
  const [photoFile, setPhotoFile] = useState(null);

  const filtered = blogs.filter((b) => {
    const q = search.toLowerCase();
    return (
      !q ||
      (b.title || "").toLowerCase().includes(q) ||
      (b.description || "").toLowerCase().includes(q)
    );
  });

  function openCreate() {
    setForm({ id: "", title: "", description: "" });
    setPhotoFile(null);
    setModalOpen(true);
  }

  function openEdit(blog) {
    setForm({
      id: blog.id,
      title: blog.title || "",
      description: blog.description || "",
    });
    setPhotoFile(null);
    setModalOpen(true);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setSaving(true);
    try {
      const fd = new FormData();
      fd.append("title", form.title);
      fd.append("description", form.description);
      if (photoFile) fd.append("photo", photoFile);

      if (!form.id) {
        await apiRequest("/blogs", { method: "POST", body: fd });
        showToast("Blog post published to Supabase Storage & DB!");
      } else {
        await apiRequest(`/blogs/${form.id}`, {
          method: "PUT",
          body: fd,
        });
        showToast("Blog post updated!");
      }
      setModalOpen(false);
      await onReload();
    } catch (err) {
      showToast(err.message || "Failed to save blog post", true);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm("Delete this blog post permanently?")) return;
    try {
      await apiRequest(`/blogs/${id}`, { method: "DELETE" });
      showToast("Blog post deleted");
      await onReload();
    } catch (err) {
      showToast(err.message || "Failed to delete blog post", true);
    }
  }

  return (
    <div className="tab-container">
      <div className="panel-header">
        <div>
          <h2>Blogs &amp; Sports News</h2>
          <p className="panel-subtitle">
            Publish tactical previews, sports articles, and platform updates.
          </p>
        </div>

        <div className="panel-actions">
          <div className="search-box">
            <Search size={16} className="search-icon" />
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search articles..."
              aria-label="Search blog articles"
            />
          </div>

          <button type="button" onClick={openCreate} className="btn btn-primary">
            <Plus size={16} />
            <span>New Blog Post</span>
          </button>
        </div>
      </div>

      <div className="table-card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Cover</th>
              <th>Title</th>
              <th>Content Preview</th>
              <th>Published Date</th>
              <th className="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={5} className="empty-cell">
                  No blog articles found.
                </td>
              </tr>
            ) : (
              filtered.map((b) => {
                const imgUrl = resolveImageUrl(b.photo);
                const excerpt =
                  (b.description || "").length > 100
                    ? `${b.description.slice(0, 100)}...`
                    : b.description || "";
                return (
                  <tr key={b.id}>
                    <td>
                      {imgUrl ? (
                        <img src={imgUrl} alt="" className="blog-thumb" />
                      ) : (
                        <div className="blog-thumb-placeholder">No Img</div>
                      )}
                    </td>
                    <td>
                      <strong>{b.title}</strong>
                    </td>
                    <td className="cell-sub" style={{ maxWidth: 380 }}>
                      {excerpt}
                    </td>
                    <td>
                      {b.date
                        ? new Date(b.date).toLocaleDateString(undefined, {
                            month: "short",
                            day: "numeric",
                            year: "numeric",
                          })
                        : "-"}
                    </td>
                    <td className="text-right">
                      <div className="row-actions">
                        <button
                          type="button"
                          onClick={() => openEdit(b)}
                          className="btn btn-ghost btn-sm"
                        >
                          <Edit2 size={14} />
                          <span>Edit</span>
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDelete(b.id)}
                          className="btn btn-danger-outline btn-sm"
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

      {modalOpen && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal-dialog">
            <div className="modal-header">
              <h3>{form.id ? "Edit Blog Post" : "Publish New Blog Post"}</h3>
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
              <div className="form-group">
                <label>Headline / Title *</label>
                <input
                  type="text"
                  required
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  placeholder="Enter blog headline..."
                />
              </div>

              <div className="form-group">
                <label>Cover Image (Supabase Storage)</label>
                <input
                  type="file"
                  accept="image/*"
                  onChange={(e) => setPhotoFile(e.target.files[0])}
                />
              </div>

              <div className="form-group">
                <label>Article Content *</label>
                <textarea
                  rows={7}
                  required
                  value={form.description}
                  onChange={(e) =>
                    setForm({ ...form, description: e.target.value })
                  }
                  placeholder="Write full article body..."
                />
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
                  {saving ? "Uploading..." : "Save Article"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
