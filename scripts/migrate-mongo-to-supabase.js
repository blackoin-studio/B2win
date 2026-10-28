/**
 * MongoDB Atlas to Supabase PostgreSQL Migration Script (Resilient Batch Edition)
 * 
 * Usage:
 *   node scripts/migrate-mongo-to-supabase.js
 */

const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../config.env") });
const mongoose = require("mongoose");
const { createClient } = require("@supabase/supabase-js");

// Models
const User = require("../Api/models/User");
const Blog = require("../Api/models/Blog");
const Prediction = require("../Api/models/Prediction");

const rawUrl = process.env.SUPABASE_URL || "";
const SUPABASE_URL = rawUrl.replace(/\/rest\/v1\/?$/, "").replace(/\/+$/, "");
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY;
const MONGODB_URI = process.env.MONGODB_URI;

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in config.env");
  process.exit(1);
}

if (!MONGODB_URI) {
  console.error("❌ Error: MONGODB_URI must be set in config.env");
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const VALID_STATUSES = ["pending", "won", "lost", "postponed", "cancelled"];

function normalizeStatus(status) {
  if (!status) return "pending";
  const lower = status.toString().trim().toLowerCase();
  return VALID_STATUSES.includes(lower) ? lower : "pending";
}

async function chunkInsert(table, items, chunkSize = 50) {
  let inserted = 0;
  for (let i = 0; i < items.length; i += chunkSize) {
    const chunk = items.slice(i, i + chunkSize);
    const { data, error } = await supabase.from(table).insert(chunk).select("id");
    if (error) {
      console.error(`  ⚠️ Batch insert error on ${table} (chunk ${i}-${i + chunk.length}):`, error.message);
      // Fallback: insert one-by-one in this chunk to rescue valid items
      for (const item of chunk) {
        const { error: singleErr } = await supabase.from(table).insert(item);
        if (singleErr) {
          console.error(`    ❌ Item failed: ${item.email || item.title || item.home_team}:`, singleErr.message);
        } else {
          inserted++;
        }
      }
    } else {
      inserted += (data ? data.length : chunk.length);
    }
  }
  return inserted;
}

async function migrateUsers() {
  console.log("\n📦 [1/3] Migrating Users -> profiles...");
  const mongoUsers = await User.find({}).lean();
  console.log(`Found ${mongoUsers.length} users in MongoDB.`);

  // 1. Fetch existing profiles in Supabase
  const { data: existingProfiles, error: fetchErr } = await supabase
    .from("profiles")
    .select("email, username");

  if (fetchErr) {
    throw new Error(`Failed to query profiles from Supabase: ${fetchErr.message}`);
  }

  const existingEmails = new Set(
    (existingProfiles || []).map((p) => (p.email || "").trim().toLowerCase())
  );
  const existingUsernames = new Set(
    (existingProfiles || []).map((p) => (p.username || "").trim().toLowerCase())
  );

  const toInsert = [];
  let skipped = 0;

  for (const user of mongoUsers) {
    const rawEmail = (user.email || "").trim();
    if (!rawEmail) {
      console.warn("  ⚠️ Skipping user without email, Mongo ID:", user._id);
      skipped++;
      continue;
    }

    const emailLower = rawEmail.toLowerCase();
    if (existingEmails.has(emailLower)) {
      skipped++;
      continue;
    }

    // Determine unique username
    let baseUsername = (user.username || "").trim();
    if (!baseUsername) {
      baseUsername = rawEmail.split("@")[0];
    }
    // Limit length to 90 chars to allow disambiguation suffix
    baseUsername = baseUsername.slice(0, 90);

    let finalUsername = baseUsername;
    let counter = 1;
    while (existingUsernames.has(finalUsername.toLowerCase())) {
      finalUsername = `${baseUsername}_${counter}`;
      counter++;
    }

    existingEmails.add(emailLower);
    existingUsernames.add(finalUsername.toLowerCase());

    toInsert.push({
      email: rawEmail,
      username: finalUsername,
      password_hash: user.password || "TEMPORARY_HASH",
      is_admin: Boolean(user.isAdmin),
      created_at: user.createdAt || new Date(),
    });
  }

  console.log(`Preparing to batch insert ${toInsert.length} profiles (${skipped} skipped/already existing)...`);
  const insertedCount = await chunkInsert("profiles", toInsert, 50);
  console.log(`✅ Profiles migration finished: ${insertedCount} inserted, ${skipped} skipped.`);
}

async function migrateBlogs() {
  console.log("\n📦 [2/3] Migrating Blogs -> blogs...");
  const mongoBlogs = await Blog.find({}).lean();
  console.log(`Found ${mongoBlogs.length} blogs in MongoDB.`);

  const { data: existingBlogs } = await supabase.from("blogs").select("title");
  const existingTitles = new Set((existingBlogs || []).map((b) => (b.title || "").trim()));

  const toInsert = [];
  for (const blog of mongoBlogs) {
    const title = (blog.title || "Untitled Blog").trim();
    if (existingTitles.has(title)) {
      continue;
    }
    existingTitles.add(title);

    toInsert.push({
      title,
      description: blog.description || "",
      photo: blog.photo || "no-league-photo.jpg",
      date: blog.date || new Date(),
    });
  }

  if (toInsert.length === 0) {
    console.log("✅ All blogs already migrated.");
    return;
  }

  const insertedCount = await chunkInsert("blogs", toInsert, 50);
  console.log(`✅ Blogs migration finished: ${insertedCount} inserted.`);
}

async function migratePredictions() {
  console.log("\n📦 [3/3] Migrating Predictions -> predictions...");
  const mongoPredictions = await Prediction.find({}).lean();
  console.log(`Found ${mongoPredictions.length} predictions in MongoDB.`);

  const { data: existingPreds } = await supabase
    .from("predictions")
    .select("home_team, away_team, date");

  const existingKeys = new Set(
    (existingPreds || []).map(
      (p) => `${p.home_team}__${p.away_team}__${new Date(p.date).toISOString().slice(0, 10)}`
    )
  );

  const toInsert = [];
  for (const pred of mongoPredictions) {
    const key = `${pred.homeTeam}__${pred.awayTeam}__${new Date(pred.date || new Date()).toISOString().slice(0, 10)}`;
    if (existingKeys.has(key)) {
      continue;
    }
    existingKeys.add(key);

    toInsert.push({
      date: pred.date || new Date(),
      time: pred.time || "00:00",
      league: pred.league || "Unknown League",
      home_team: pred.homeTeam || "Home Team",
      away_team: pred.awayTeam || "Away Team",
      league_logo: pred.leagueLogo || "no-league-photo.jpg",
      home_logo: pred.homeLogo || "no-home-photo.jpg",
      away_logo: pred.awayLogo || "no-away-photo.jpg",
      score: pred.score || "-",
      odds: pred.odds ? String(pred.odds) : "1.00",
      status: normalizeStatus(pred.status),
      tip: pred.tip || "N/A",
    });
  }

  if (toInsert.length === 0) {
    console.log("✅ All predictions already migrated.");
    return;
  }

  const insertedCount = await chunkInsert("predictions", toInsert, 50);
  console.log(`✅ Predictions migration finished: ${insertedCount} inserted.`);
}

async function run() {
  console.log("🚀 Starting MongoDB to Supabase migration...");
  try {
    await mongoose.connect(MONGODB_URI, { dbName: "b2win" });
    console.log("✅ Connected to MongoDB Atlas.");

    await migrateUsers();
    await migrateBlogs();
    await migratePredictions();

    console.log("\n🎉 Full migration completed successfully!");
  } catch (err) {
    console.error("💥 Migration failed:", err);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

run();
