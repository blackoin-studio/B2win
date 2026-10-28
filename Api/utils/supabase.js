const { createClient } = require("@supabase/supabase-js");

const rawUrl = process.env.SUPABASE_URL || "";
const supabaseUrl = rawUrl.replace(/\/rest\/v1\/?$/, "").replace(/\/+$/, "");
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseKey = supabaseServiceKey || supabaseAnonKey;

if (!supabaseUrl || !supabaseKey) {
  console.warn(
    "[Supabase] Warning: SUPABASE_URL and/or SUPABASE_SERVICE_ROLE_KEY are not configured in environment variables."
  );
}

/**
 * Primary backend client (uses Service Role Key to bypass RLS and access auth.admin)
 */
const supabase = createClient(
  supabaseUrl || "https://placeholder.supabase.co",
  supabaseKey || "placeholder",
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  }
);

/**
 * Creates a fresh, isolated Supabase client for end-user auth operations
 * (e.g. signInWithPassword, refreshSession) so that signing in a user
 * never mutates the Authorization header on the shared service_role client.
 */
function createAuthClient() {
  return createClient(
    supabaseUrl || "https://placeholder.supabase.co",
    supabaseAnonKey || supabaseKey || "placeholder",
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
    }
  );
}

supabase.createAuthClient = createAuthClient;

module.exports = supabase;
