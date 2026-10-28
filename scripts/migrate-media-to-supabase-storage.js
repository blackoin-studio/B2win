/**
 * Migrates existing local images in public/ referenced by Supabase
 * predictions & blogs into the public "b2win-media" Supabase Storage bucket.
 *
 * Usage:
 *   node scripts/migrate-media-to-supabase-storage.js
 */

const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../config.env") });
const supabase = require("../Api/utils/supabase");
const {
  BUCKET_NAME,
  ensureBucket,
} = require("../Api/utils/supabaseStorage");

const PUBLIC_DIR = path.resolve(__dirname, "../public");

function getMimeType(filename) {
  const ext = path.extname(filename).toLowerCase();
  if (ext === ".png") return "image/png";
  if (ext === ".gif") return "image/gif";
  if (ext === ".webp") return "image/webp";
  return "image/jpeg";
}

async function uploadLocalIfPresent(filename, folder) {
  if (
    !filename ||
    filename.startsWith("no-") ||
    filename.startsWith("http://") ||
    filename.startsWith("https://")
  ) {
    return null;
  }

  const localPath = path.join(PUBLIC_DIR, filename);
  if (!fs.existsSync(localPath)) {
    return null;
  }

  const buffer = fs.readFileSync(localPath);
  const storagePath = `${folder}/${filename}`;

  const { error } = await supabase.storage
    .from(BUCKET_NAME)
    .upload(storagePath, buffer, {
      contentType: getMimeType(filename),
      upsert: true,
    });

  if (error) {
    console.warn(`  ⚠️ Failed to upload ${filename}:`, error.message);
    return null;
  }

  const { data } = supabase.storage.from(BUCKET_NAME).getPublicUrl(storagePath);
  return data.publicUrl;
}

async function main() {
  console.log("🚀 Ensuring Supabase Storage bucket:", BUCKET_NAME);
  await ensureBucket();

  // 1. Migrate prediction logos
  const { data: predictions } = await supabase.from("predictions").select("*");
  let updatedPreds = 0;

  for (const p of predictions || []) {
    const updates = {};
    const leagueUrl = await uploadLocalIfPresent(p.league_logo, "predictions");
    const homeUrl = await uploadLocalIfPresent(p.home_logo, "predictions");
    const awayUrl = await uploadLocalIfPresent(p.away_logo, "predictions");

    if (leagueUrl) updates.league_logo = leagueUrl;
    if (homeUrl) updates.home_logo = homeUrl;
    if (awayUrl) updates.away_logo = awayUrl;

    if (Object.keys(updates).length > 0) {
      await supabase.from("predictions").update(updates).eq("id", p.id);
      updatedPreds++;
    }
  }
  console.log(`✅ Migrated local logos for ${updatedPreds} predictions.`);

  // 2. Migrate blog photos
  const { data: blogs } = await supabase.from("blogs").select("*");
  let updatedBlogs = 0;

  for (const b of blogs || []) {
    const photoUrl = await uploadLocalIfPresent(b.photo, "blogs");
    if (photoUrl) {
      await supabase.from("blogs").update({ photo: photoUrl }).eq("id", b.id);
      updatedBlogs++;
    }
  }
  console.log(`✅ Migrated local photos for ${updatedBlogs} blogs.`);
}

main();

