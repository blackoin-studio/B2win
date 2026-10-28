/**
 * CLI Utility to Promote an Existing User to Admin (or Create a New Admin User)
 * Synchronizes both Supabase Auth (auth.users) and public.profiles.
 *
 * Usage:
 *   1. Promote existing user by email:
 *      node scripts/make-admin.js admin@example.com
 *
 *   2. Create a new admin user (or update existing user's password + promote):
 *      node scripts/make-admin.js admin@example.com AdminUsername StrongPassword123
 */

const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "../config.env") });
const bcrypt = require("bcryptjs");
const supabase = require("../Api/utils/supabase");

async function findAuthUserByEmail(email) {
  const { data, error } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  });
  if (error || !data?.users) return null;
  const target = email.trim().toLowerCase();
  return (
    data.users.find((u) => (u.email || "").toLowerCase() === target) || null
  );
}

async function main() {
  const [emailArg, usernameArg, passwordArg] = process.argv.slice(2);

  if (!emailArg) {
    console.log("Usage:");
    console.log("  Promote existing user:  node scripts/make-admin.js <email>");
    console.log(
      "  Create/set admin user:  node scripts/make-admin.js <email> <username> <password>"
    );
    process.exit(1);
  }

  const email = emailArg.trim().toLowerCase();

  // 1. Check existing profile in public.profiles
  const { data: existingProfile, error: findErr } = await supabase
    .from("profiles")
    .select("id, email, username, is_admin")
    .ilike("email", email)
    .maybeSingle();

  if (findErr) {
    console.error("❌ Supabase query error:", findErr.message);
    process.exit(1);
  }

  // 2. Check existing user in Supabase Auth (auth.users)
  let authUser = await findAuthUserByEmail(email);

  if (existingProfile) {
    const username = usernameArg ? usernameArg.trim() : existingProfile.username;
    const updatePayload = { is_admin: true, username };

    if (passwordArg) {
      const salt = await bcrypt.genSalt(10);
      updatePayload.password_hash = await bcrypt.hash(passwordArg, salt);
    }

    // Update or create in Supabase Auth
    if (authUser) {
      const authUpdate = {
        email_confirm: true,
        user_metadata: { ...authUser.user_metadata, username },
        app_metadata: {
          ...authUser.app_metadata,
          role: "admin",
          is_admin: true,
        },
      };
      if (passwordArg) authUpdate.password = passwordArg;
      await supabase.auth.admin.updateUserById(authUser.id, authUpdate);
    } else if (passwordArg) {
      const { data: createdAuth, error: authErr } =
        await supabase.auth.admin.createUser({
          id: existingProfile.id,
          email,
          password: passwordArg,
          email_confirm: true,
          user_metadata: { username },
          app_metadata: { role: "admin", is_admin: true },
        });
      if (authErr) {
        console.warn("⚠️ Supabase Auth create warning:", authErr.message);
      } else {
        authUser = createdAuth.user;
      }
    }

    const { data: updated, error: updateErr } = await supabase
      .from("profiles")
      .update(updatePayload)
      .eq("id", existingProfile.id)
      .select("id, email, username, is_admin")
      .single();

    if (updateErr) {
      console.error("❌ Failed to promote user:", updateErr.message);
      process.exit(1);
    }

    console.log("✅ User promoted to Admin (Profile + Supabase Auth):", updated);
    process.exit(0);
  }

  // Creating a brand-new admin user
  if (!usernameArg || !passwordArg) {
    console.error(
      `❌ No user found with email "${email}". To create a new admin user, provide <username> and <password>:\n   node scripts/make-admin.js ${email} <username> <password>`
    );
    process.exit(1);
  }

  const username = usernameArg.trim();
  let targetId;

  if (authUser) {
    targetId = authUser.id;
    await supabase.auth.admin.updateUserById(authUser.id, {
      password: passwordArg,
      email_confirm: true,
      user_metadata: { username },
      app_metadata: { role: "admin", is_admin: true },
    });
  } else {
    const { data: createdAuth, error: authErr } =
      await supabase.auth.admin.createUser({
        email,
        password: passwordArg,
        email_confirm: true,
        user_metadata: { username },
        app_metadata: { role: "admin", is_admin: true },
      });

    if (authErr) {
      console.error("❌ Failed to create Supabase Auth admin:", authErr.message);
      process.exit(1);
    }
    targetId = createdAuth.user.id;
  }

  const salt = await bcrypt.genSalt(10);
  const password_hash = await bcrypt.hash(passwordArg, salt);

  const { data: created, error: createErr } = await supabase
    .from("profiles")
    .upsert(
      {
        id: targetId,
        email,
        username,
        password_hash,
        is_admin: true,
      },
      { onConflict: "id" }
    )
    .select("id, email, username, is_admin")
    .single();

  if (createErr) {
    console.error("❌ Failed to create admin profile:", createErr.message);
    process.exit(1);
  }

  console.log("✅ New Admin user created in Supabase Auth & profiles:", created);
  process.exit(0);
}

main();
