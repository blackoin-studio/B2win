(() => {
  const FALLBACK_IMG = "./images/logo.png";
  let allPredictions = [];
  let allBlogs = [];
  let currentFilter = "all";

  function escapeHtml(str) {
    if (str === null || str === undefined) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function resolveImageUrl(filename) {
    if (!filename || filename.startsWith("no-")) {
      return FALLBACK_IMG;
    }
    if (filename.startsWith("http://") || filename.startsWith("https://")) {
      return filename;
    }
    return `/public/${encodeURIComponent(filename)}`;
  }

  function formatDate(dateStr) {
    if (!dateStr) return "";
    const d = new Date(dateStr);
    if (Number.isNaN(d.getTime())) return String(dateStr);
    return d.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  }

  function renderPredictions() {
    const grid = document.getElementById("predictionsGrid");
    if (!grid) return;

    grid.setAttribute("aria-busy", "false");

    const filtered =
      currentFilter === "all"
        ? allPredictions
        : allPredictions.filter(
            (p) => (p.status || "pending").toLowerCase() === currentFilter
          );

    if (filtered.length === 0) {
      grid.innerHTML = `
        <div class="empty-state">
          <p>No predictions match the <strong>${escapeHtml(
            currentFilter
          )}</strong> filter right now.</p>
        </div>
      `;
      return;
    }

    grid.innerHTML = filtered
      .slice(0, 9)
      .map((p) => {
        const status = (p.status || "pending").toLowerCase();
        const leagueLogo = resolveImageUrl(p.leagueLogo);
        const homeLogo = resolveImageUrl(p.homeLogo);
        const awayLogo = resolveImageUrl(p.awayLogo);

        return `
          <article class="prediction-card">
            <div class="pred-top">
              <div class="pred-league">
                <img
                  src="${leagueLogo}"
                  alt=""
                  class="league-logo"
                  loading="lazy"
                  onerror="this.onerror=null;this.src='${FALLBACK_IMG}';"
                />
                <span>${escapeHtml(p.league || "Football League")}</span>
              </div>
              <span class="pred-status status-${escapeHtml(status)}">
                ${escapeHtml(status)}
              </span>
            </div>

            <div class="pred-teams">
              <div class="team-col">
                <img
                  src="${homeLogo}"
                  alt="${escapeHtml(p.homeTeam)}"
                  class="team-logo"
                  loading="lazy"
                  onerror="this.onerror=null;this.src='${FALLBACK_IMG}';"
                />
                <span class="team-name">${escapeHtml(p.homeTeam)}</span>
              </div>

              <div class="match-center">
                <span class="match-score">${escapeHtml(p.score || "VS")}</span>
                <span class="match-time">${escapeHtml(
                  p.time || "00:00"
                )} &middot; ${escapeHtml(formatDate(p.date))}</span>
              </div>

              <div class="team-col">
                <img
                  src="${awayLogo}"
                  alt="${escapeHtml(p.awayTeam)}"
                  class="team-logo"
                  loading="lazy"
                  onerror="this.onerror=null;this.src='${FALLBACK_IMG}';"
                />
                <span class="team-name">${escapeHtml(p.awayTeam)}</span>
              </div>
            </div>

            <div class="pred-footer">
              <span class="tip-badge">Tip: ${escapeHtml(p.tip || "N/A")}</span>
              <span class="odds-badge">Odds ${escapeHtml(
                p.odds || "1.00"
              )}</span>
            </div>
          </article>
        `;
      })
      .join("");
  }

  function renderBlogs() {
    const grid = document.getElementById("blogsGrid");
    if (!grid) return;

    grid.setAttribute("aria-busy", "false");

    if (allBlogs.length === 0) {
      grid.innerHTML = `
        <div class="empty-state">
          <p>No blog articles published yet. Check back soon!</p>
        </div>
      `;
      return;
    }

    grid.innerHTML = allBlogs
      .slice(0, 6)
      .map((b, idx) => {
        const photoUrl = resolveImageUrl(b.photo);
        const excerpt =
          (b.description || "").length > 130
            ? `${b.description.slice(0, 130)}...`
            : b.description || "";

        return `
          <article class="blog-card">
            <img
              src="${photoUrl}"
              alt="${escapeHtml(b.title)}"
              class="blog-cover"
              loading="lazy"
              onerror="this.onerror=null;this.src='${FALLBACK_IMG}';"
            />
            <div class="blog-body">
              <span class="blog-date">${escapeHtml(formatDate(b.date))}</span>
              <h3 class="blog-title">${escapeHtml(b.title)}</h3>
              <p class="blog-excerpt">${escapeHtml(excerpt)}</p>
              <button
                type="button"
                class="read-more-btn"
                data-blog-index="${idx}"
              >
                Read Full Article &rarr;
              </button>
            </div>
          </article>
        `;
      })
      .join("");
  }

  async function loadLiveContent() {
    try {
      const [predRes, blogRes] = await Promise.all([
        fetch("/api/v1/predictions"),
        fetch("/api/v1/blogs"),
      ]);

      if (predRes.ok) {
        const data = await predRes.json();
        allPredictions = Array.isArray(data) ? data : [];
      }
      if (blogRes.ok) {
        const data = await blogRes.json();
        allBlogs = Array.isArray(data) ? data : [];
      }
    } catch (err) {
      console.error("Failed to load live feed:", err);
    } finally {
      renderPredictions();
      renderBlogs();
    }
  }

  function setupInteractions() {
    // Year in footer
    const yearEl = document.getElementById("currentYear");
    if (yearEl) yearEl.textContent = new Date().getFullYear();

    // Mobile Menu Toggle
    const mobileBtn = document.getElementById("mobileMenuBtn");
    const navMenu = document.getElementById("navMenu");
    if (mobileBtn && navMenu) {
      mobileBtn.addEventListener("click", () => {
        const isOpen = navMenu.classList.toggle("open");
        mobileBtn.setAttribute("aria-expanded", String(isOpen));
      });

      navMenu.querySelectorAll("a").forEach((link) => {
        link.addEventListener("click", () => {
          navMenu.classList.remove("open");
          mobileBtn.setAttribute("aria-expanded", "false");
        });
      });
    }

    // Prediction status filter pills
    document.querySelectorAll(".filter-pill").forEach((btn) => {
      btn.addEventListener("click", () => {
        document.querySelectorAll(".filter-pill").forEach((b) => {
          b.classList.remove("active");
          b.setAttribute("aria-selected", "false");
        });
        btn.classList.add("active");
        btn.setAttribute("aria-selected", "true");
        currentFilter = btn.getAttribute("data-filter") || "all";
        renderPredictions();
      });
    });

    // Blog Reader Modal
    const modal = document.getElementById("blogModal");
    const closeBtn = document.getElementById("closeBlogModalBtn");
    const blogsGrid = document.getElementById("blogsGrid");

    function closeModal() {
      if (modal) modal.hidden = true;
    }

    if (blogsGrid && modal) {
      blogsGrid.addEventListener("click", (e) => {
        const btn = e.target.closest("[data-blog-index]");
        if (!btn) return;
        const idx = Number(btn.getAttribute("data-blog-index"));
        const blog = allBlogs[idx];
        if (!blog) return;

        document.getElementById("blogModalTitle").textContent =
          blog.title || "";
        document.getElementById("blogModalDate").textContent = formatDate(
          blog.date
        );
        document.getElementById("blogModalContent").textContent =
          blog.description || "";
        const imgEl = document.getElementById("blogModalImage");
        imgEl.src = resolveImageUrl(blog.photo);
        imgEl.alt = blog.title || "";
        modal.hidden = false;
        closeBtn?.focus();
      });
    }

    closeBtn?.addEventListener("click", closeModal);
    modal?.addEventListener("click", (e) => {
      if (e.target === modal) closeModal();
    });
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape" && modal && !modal.hidden) {
        closeModal();
      }
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    setupInteractions();
    loadLiveContent();
  });
})();
