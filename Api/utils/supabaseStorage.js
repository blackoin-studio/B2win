const path = require("path");
const supabase = require("./supabase");

const BUCKET_NAME = process.env.SUPABASE_STORAGE_BUCKET || "b2win-media";
let bucketInitialized = false;

/**
 * Ensures the public Supabase Storage bucket exists.
 */
async function ensureBucket() {
  if (bucketInitialized) return;

  try {
    const { data: buckets, error: listErr } =
      await supabase.storage.listBuckets();
    if (!listErr && Array.isArray(buckets)) {
      const exists = buckets.some((b) => b.name === BUCKET_NAME);
      if (!exists) {
        const { error: createErr } = await supabase.storage.createBucket(
          BUCKET_NAME,
          {
            public: true,
            fileSizeLimit: 5 * 1024 * 1024,
            allowedMimeTypes: [
              "image/jpeg",
              "image/png",
              "image/gif",
              "image/webp",
            ],
          }
        );
        if (createErr) {
          console.warn(
            `[Supabase Storage] Could not auto-create bucket "${BUCKET_NAME}":`,
            createErr.message
          );
        } else {
          console.log(
            `[Supabase Storage] Created public bucket "${BUCKET_NAME}".`
          );
        }
      }
      bucketInitialized = true;
    }
  } catch (err) {
    console.warn("[Supabase Storage] Bucket check warning:", err.message);
  }
}

/**
 * Uploads a Multer file (from memoryStorage) to Supabase Storage
 * and returns its permanent public URL.
 *
 * @param {Object} file - Multer file object ({ buffer, originalname, mimetype })
 * @param {string} folder - Folder prefix inside the bucket (e.g. "predictions" or "blogs")
 * @returns {Promise<string>} Public URL of the uploaded image
 */
async function uploadFileToSupabase(file, folder = "uploads") {
  if (!file || !file.buffer) {
    return null;
  }

  await ensureBucket();

  const ext = path.extname(file.originalname || "").toLowerCase() || ".jpg";
  const uniqueName = `${folder}/${Date.now()}-${Math.round(
    Math.random() * 1e6
  )}${ext}`;

  const { error: uploadError } = await supabase.storage
    .from(BUCKET_NAME)
    .upload(uniqueName, file.buffer, {
      contentType: file.mimetype || "image/jpeg",
      upsert: true,
    });

  if (uploadError) {
    throw new Error(`Supabase Storage upload failed: ${uploadError.message}`);
  }

  const { data } = supabase.storage.from(BUCKET_NAME).getPublicUrl(uniqueName);
  return data.publicUrl;
}

module.exports = {
  BUCKET_NAME,
  ensureBucket,
  uploadFileToSupabase,
};

