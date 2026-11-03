const supabase = require("../utils/supabase");
const { MEDIA_BUCKET } = require("../utils/supabaseStorage");

const SETTINGS_KEY = "google_ads";
const STORAGE_CONFIG_PATH = "_config/google_ads.json";

// Official Google AdMob Test Ad Unit IDs (safe default when testMode is true)
const DEFAULT_AD_SETTINGS = {
  adsEnabled: false,
  testMode: true,
  bannerEnabled: true,
  interstitialEnabled: true,
  showOnHome: true,
  showOnBlog: true,
  interstitialInterval: 3,
  androidBannerUnitId: "ca-app-pub-3940256099942544/6300978111",
  iosBannerUnitId: "ca-app-pub-3940256099942544/2934735716",
  androidInterstitialUnitId: "ca-app-pub-3940256099942544/1033173712",
  iosInterstitialUnitId: "ca-app-pub-3940256099942544/4411468910",
  updatedAt: null,
  updatedBy: null,
};

let inMemoryAdSettingsCache = null;

function normalizeAdSettings(raw = {}) {
  const interval = parseInt(raw.interstitialInterval, 10);
  return {
    adsEnabled: Boolean(raw.adsEnabled ?? DEFAULT_AD_SETTINGS.adsEnabled),
    testMode: Boolean(raw.testMode ?? DEFAULT_AD_SETTINGS.testMode),
    bannerEnabled: Boolean(
      raw.bannerEnabled ?? DEFAULT_AD_SETTINGS.bannerEnabled
    ),
    interstitialEnabled: Boolean(
      raw.interstitialEnabled ?? DEFAULT_AD_SETTINGS.interstitialEnabled
    ),
    showOnHome: Boolean(raw.showOnHome ?? DEFAULT_AD_SETTINGS.showOnHome),
    showOnBlog: Boolean(raw.showOnBlog ?? DEFAULT_AD_SETTINGS.showOnBlog),
    interstitialInterval:
      !Number.isNaN(interval) && interval >= 1 && interval <= 50
        ? interval
        : DEFAULT_AD_SETTINGS.interstitialInterval,
    androidBannerUnitId:
      String(
        raw.androidBannerUnitId ?? DEFAULT_AD_SETTINGS.androidBannerUnitId
      ).trim() || DEFAULT_AD_SETTINGS.androidBannerUnitId,
    iosBannerUnitId:
      String(
        raw.iosBannerUnitId ?? DEFAULT_AD_SETTINGS.iosBannerUnitId
      ).trim() || DEFAULT_AD_SETTINGS.iosBannerUnitId,
    androidInterstitialUnitId:
      String(
        raw.androidInterstitialUnitId ??
          DEFAULT_AD_SETTINGS.androidInterstitialUnitId
      ).trim() || DEFAULT_AD_SETTINGS.androidInterstitialUnitId,
    iosInterstitialUnitId:
      String(
        raw.iosInterstitialUnitId ?? DEFAULT_AD_SETTINGS.iosInterstitialUnitId
      ).trim() || DEFAULT_AD_SETTINGS.iosInterstitialUnitId,
    updatedAt: raw.updatedAt || null,
    updatedBy: raw.updatedBy || null,
  };
}

async function readSettingsFromSupabase() {
  // 1. Try reading from public.app_settings table first
  try {
    const { data, error } = await supabase
      .from("app_settings")
      .select("value, updated_at")
      .eq("key", SETTINGS_KEY)
      .maybeSingle();

    if (!error && data && data.value) {
      const merged = normalizeAdSettings({
        ...data.value,
        updatedAt: data.value.updatedAt || data.updated_at,
      });
      inMemoryAdSettingsCache = merged;
      return merged;
    }
  } catch (_) {
    // Table may not exist yet; fall through to Supabase Storage config
  }

  // 2. Fallback: Read JSON config from Supabase Storage bucket (`b2win-media/_config/google_ads.json`)
  try {
    const { data: blob, error: storageErr } = await supabase.storage
      .from(MEDIA_BUCKET)
      .download(STORAGE_CONFIG_PATH);

    if (!storageErr && blob) {
      const text = await blob.text();
      const parsed = JSON.parse(text);
      const merged = normalizeAdSettings(parsed);
      inMemoryAdSettingsCache = merged;
      return merged;
    }
  } catch (_) {
    // Ignore storage read errors if not yet initialized
  }

  if (inMemoryAdSettingsCache) {
    return inMemoryAdSettingsCache;
  }

  return { ...DEFAULT_AD_SETTINGS };
}

async function writeSettingsToSupabase(settings, adminUser) {
  const payload = normalizeAdSettings({
    ...settings,
    updatedAt: new Date().toISOString(),
    updatedBy: adminUser?.email || adminUser?.id || "admin",
  });

  inMemoryAdSettingsCache = payload;

  // 1. Persist to public.app_settings table if available
  try {
    await supabase.from("app_settings").upsert(
      {
        key: SETTINGS_KEY,
        value: payload,
        updated_by: adminUser?.id || null,
        updated_at: payload.updatedAt,
      },
      { onConflict: "key" }
    );
  } catch (_) {
    // Ignore if table hasn't been created yet
  }

  // 2. Also persist to Supabase Storage (`b2win-media/_config/google_ads.json`) for guaranteed durability
  try {
    const buffer = Buffer.from(JSON.stringify(payload, null, 2), "utf-8");
    await supabase.storage.from(MEDIA_BUCKET).upload(STORAGE_CONFIG_PATH, buffer, {
      contentType: "application/json",
      upsert: true,
    });
  } catch (err) {
    console.warn("Storage config backup warning:", err.message);
  }

  return payload;
}

// @desc    Get dynamic Google Ads (AdMob) configuration for Mobile App & Admin Panel
// @route   GET /api/v1/settings/ads
// @access  Public
const getAdSettings = async (req, res) => {
  try {
    const settings = await readSettingsFromSupabase();
    return res.status(200).json({
      success: true,
      data: settings,
    });
  } catch (error) {
    console.error("Get ad settings error:", error.message);
    return res.status(200).json({
      success: true,
      data: inMemoryAdSettingsCache || DEFAULT_AD_SETTINGS,
    });
  }
};

// @desc    Update dynamic Google Ads (AdMob) configuration
// @route   PUT /api/v1/settings/ads
// @access  Private / Admin Only
const updateAdSettings = async (req, res) => {
  try {
    const current = await readSettingsFromSupabase();
    const updated = await writeSettingsToSupabase(
      {
        ...current,
        ...req.body,
      },
      req.user
    );

    return res.status(200).json({
      success: true,
      message: updated.adsEnabled
        ? "Google Ads enabled and configuration saved"
        : "Google Ads disabled and configuration saved",
      data: updated,
    });
  } catch (error) {
    console.error("Update ad settings error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to update Google Ads settings",
    });
  }
};

// ============================================================================
// IN-APP ANNOUNCEMENTS & BROADCAST NOTIFICATIONS
// ============================================================================
const ANNOUNCEMENTS_KEY = "announcements";
const ANNOUNCEMENTS_STORAGE_PATH = "_config/announcements.json";

const DEFAULT_ANNOUNCEMENTS = [
  {
    id: "welcome-b2win-v2",
    title: "Welcome to B2win v2.0!",
    body: "Explore AI Match Insights, Smart Slip Builder, Saved Slips, and VIP Tips.",
    type: "promo",
    createdAt: new Date().toISOString(),
  },
];

let inMemoryAnnouncementsCache = null;

async function readAnnouncementsFromSupabase() {
  try {
    const { data, error } = await supabase
      .from("app_settings")
      .select("value")
      .eq("key", ANNOUNCEMENTS_KEY)
      .maybeSingle();

    if (!error && data && Array.isArray(data.value?.items)) {
      inMemoryAnnouncementsCache = data.value.items;
      return data.value.items;
    }
  } catch (_) {}

  try {
    const { data: blob, error: storageErr } = await supabase.storage
      .from(MEDIA_BUCKET)
      .download(ANNOUNCEMENTS_STORAGE_PATH);

    if (!storageErr && blob) {
      const text = await blob.text();
      const parsed = JSON.parse(text);
      if (Array.isArray(parsed?.items)) {
        inMemoryAnnouncementsCache = parsed.items;
        return parsed.items;
      }
    }
  } catch (_) {}

  return inMemoryAnnouncementsCache || DEFAULT_ANNOUNCEMENTS;
}

async function writeAnnouncementsToSupabase(items, adminUser) {
  const cleanItems = Array.isArray(items) ? items.slice(0, 30) : [];
  inMemoryAnnouncementsCache = cleanItems;
  const payload = {
    items: cleanItems,
    updatedAt: new Date().toISOString(),
    updatedBy: adminUser?.email || "admin",
  };

  try {
    await supabase.from("app_settings").upsert(
      {
        key: ANNOUNCEMENTS_KEY,
        value: payload,
        updated_by: adminUser?.id || null,
        updated_at: payload.updatedAt,
      },
      { onConflict: "key" }
    );
  } catch (_) {}

  try {
    const buffer = Buffer.from(JSON.stringify(payload, null, 2), "utf-8");
    await supabase.storage
      .from(MEDIA_BUCKET)
      .upload(ANNOUNCEMENTS_STORAGE_PATH, buffer, {
        contentType: "application/json",
        upsert: true,
      });
  } catch (_) {}

  return cleanItems;
}

const getAnnouncements = async (req, res) => {
  try {
    const items = await readAnnouncementsFromSupabase();
    return res.status(200).json({
      success: true,
      data: items,
    });
  } catch (err) {
    return res.status(200).json({
      success: true,
      data: DEFAULT_ANNOUNCEMENTS,
    });
  }
};

const createAnnouncement = async (req, res) => {
  try {
    const { title, body, type = "tip" } = req.body || {};
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: "Title and message body are required",
      });
    }

    const current = await readAnnouncementsFromSupabase();
    const newItem = {
      id: `ann-${Date.now()}`,
      title: String(title).trim(),
      body: String(body).trim(),
      type: ["tip", "promo", "news"].includes(type) ? type : "tip",
      createdAt: new Date().toISOString(),
    };

    const updated = await writeAnnouncementsToSupabase(
      [newItem, ...current],
      req.user
    );

    return res.status(201).json({
      success: true,
      message: "Announcement broadcasted to all mobile users",
      data: updated,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      error: "Failed to broadcast announcement",
    });
  }
};

const deleteAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;
    const current = await readAnnouncementsFromSupabase();
    const filtered = current.filter((item) => item.id !== id);
    const updated = await writeAnnouncementsToSupabase(filtered, req.user);

    return res.status(200).json({
      success: true,
      message: "Announcement removed",
      data: updated,
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      error: "Failed to delete announcement",
    });
  }
};

module.exports = {
  getAdSettings,
  updateAdSettings,
  getAnnouncements,
  createAnnouncement,
  deleteAnnouncement,
  DEFAULT_AD_SETTINGS,
};

