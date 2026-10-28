const supabase = require("../utils/supabase");
const bcrypt = require("bcryptjs");

const mapUser = (user) => ({
  _id: user.id,
  id: user.id,
  email: user.email,
  username: user.username,
  isAdmin: Boolean(user.is_admin),
  createdAt: user.created_at,
});

function getDefaultConfirmRedirect(req) {
  if (process.env.AUTH_REDIRECT_URL) {
    return process.env.AUTH_REDIRECT_URL;
  }
  const proto = req.headers["x-forwarded-proto"] || req.protocol || "http";
  const host = req.get("host") || `localhost:${process.env.PORT || 5000}`;
  return `${proto}://${host}/api/v1/users/confirm`;
}

/**
 * Helper: Find a Supabase Auth user by email or ID
 */
async function findAuthUserByEmailOrId(id, email) {
  if (id) {
    const { data, error } = await supabase.auth.admin.getUserById(id);
    if (!error && data?.user) return data.user;
  }
  if (email) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });
    if (!error && data?.users) {
      const target = email.trim().toLowerCase();
      return (
        data.users.find((u) => (u.email || "").toLowerCase() === target) || null
      );
    }
  }
  return null;
}

/**
 * Helper: Ensure a Supabase Auth user has a corresponding row in public.profiles
 */
async function ensureProfileForAuthUser(authUser) {
  const emailClean = (authUser.email || "").trim().toLowerCase();

  let { data: profile } = await supabase
    .from("profiles")
    .select("*")
    .or(`id.eq.${authUser.id},email.ilike.${emailClean}`)
    .maybeSingle();

  if (profile) {
    return profile;
  }

  const isAdmin =
    Boolean(authUser.app_metadata?.is_admin) ||
    authUser.app_metadata?.role === "admin";

  const baseUsername = (
    authUser.user_metadata?.username ||
    authUser.user_metadata?.full_name ||
    authUser.user_metadata?.name ||
    emailClean.split("@")[0] ||
    "user"
  )
    .toString()
    .replace(/\s+/g, "_")
    .slice(0, 80);

  const uniqueUsername = `${baseUsername}_${authUser.id.slice(0, 5)}`;

  const { data: createdProfile } = await supabase
    .from("profiles")
    .upsert(
      {
        id: authUser.id,
        email: emailClean,
        username: uniqueUsername,
        password_hash: "SUPABASE_OAUTH",
        is_admin: isAdmin,
      },
      { onConflict: "email" }
    )
    .select("*")
    .maybeSingle();

  return (
    createdProfile || {
      id: authUser.id,
      email: emailClean,
      username: uniqueUsername,
      is_admin: isAdmin,
      created_at: authUser.created_at,
    }
  );
}

/**
 * POST /api/v1/users/register
 * Registers user via Supabase Auth (triggers confirmation email when enabled in Supabase)
 * and syncs profile in public.profiles.
 */
exports.registerUser = async (req, res) => {
  const { email, password, username } = req.body;

  if (!email || !password || !username) {
    return res
      .status(400)
      .json({ error: "Email, password, and username are required" });
  }

  if (password.length < 6) {
    return res
      .status(400)
      .json({ error: "Password must be at least 6 characters long" });
  }

  const emailClean = email.trim().toLowerCase();
  const usernameClean = username.trim();

  // 1. Check if email or username already exists in public.profiles
  const { data: existingUser, error: checkError } = await supabase
    .from("profiles")
    .select("id, email, username")
    .or(`email.ilike.${emailClean},username.ilike.${usernameClean}`)
    .maybeSingle();

  if (checkError && checkError.code !== "PGRST116") {
    console.error("Error checking existing user:", checkError);
  }

  if (existingUser) {
    return res
      .status(400)
      .json({ error: "Email or Username already exists" });
  }

  try {
    const authClient = supabase.createAuthClient();
    const emailRedirectTo = getDefaultConfirmRedirect(req);

    // 2. Sign up via Supabase Auth (triggers Confirmation Email if enabled in Supabase project)
    let { data: signUpData, error: signUpError } =
      await authClient.auth.signUp({
        email: emailClean,
        password,
        options: {
          emailRedirectTo,
          data: { username: usernameClean },
        },
      });

    let authUser = signUpData?.user;
    let emailConfirmationRequired = Boolean(
      authUser && !signUpData?.session && !authUser.email_confirmed_at
    );

    // Fallback to admin.createUser if public signUp is rate-limited by SMTP
    if (signUpError || !authUser) {
      const { data: adminAuthData, error: adminAuthError } =
        await supabase.auth.admin.createUser({
          email: emailClean,
          password,
          email_confirm: true,
          user_metadata: { username: usernameClean },
          app_metadata: { role: "user", is_admin: false },
        });

      if (adminAuthError) {
        return res.status(400).json({ error: adminAuthError.message });
      }
      authUser = adminAuthData.user;
      emailConfirmationRequired = false;
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    // 3. Upsert linked profile in public.profiles
    const { data: newUser, error: insertError } = await supabase
      .from("profiles")
      .upsert(
        {
          id: authUser.id,
          email: emailClean,
          username: usernameClean,
          password_hash,
          is_admin: false,
        },
        { onConflict: "email" }
      )
      .select()
      .single();

    if (insertError) {
      console.error("Supabase profiles insert error:", insertError);
      return res.status(500).json({ error: "Failed to register user" });
    }

    const message = emailConfirmationRequired
      ? "Account created! Please check your email inbox to confirm your address."
      : "User registered successfully";

    res.status(201).json({
      message,
      emailConfirmationRequired,
      user: mapUser(newUser),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to register user" });
  }
};

/**
 * POST /api/v1/users/resend-confirmation
 * Resends the Supabase Auth signup confirmation email.
 */
exports.resendConfirmation = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: "Email is required" });
  }

  try {
    const authClient = supabase.createAuthClient();
    const { error } = await authClient.auth.resend({
      type: "signup",
      email: email.trim().toLowerCase(),
      options: {
        emailRedirectTo: getDefaultConfirmRedirect(req),
      },
    });

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(200).json({
      success: true,
      message: "Confirmation email sent! Please check your inbox and spam folder.",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * GET /api/v1/users/confirm
 * Handles email confirmation link redirects from Supabase Auth.
 */
exports.confirmEmailCallback = async (req, res) => {
  const { token_hash, type } = req.query;

  if (token_hash && type) {
    const authClient = supabase.createAuthClient();
    await authClient.auth.verifyOtp({ token_hash, type }).catch(() => {});
  }

  res.status(200).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Email Confirmed — B2WIN</title>
  <style>
    body { font-family: system-ui, sans-serif; background: #0b0d13; color: #f8fafc; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; }
    .card { max-width: 420px; width: 100%; background: #171c29; border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; padding: 36px 28px; text-align: center; }
    .badge { display: inline-block; background: rgba(16,185,129,0.15); color: #10b981; padding: 6px 14px; border-radius: 999px; font-weight: 700; font-size: 13px; margin-bottom: 16px; }
    h1 { font-size: 24px; margin: 0 0 10px; }
    p { color: #94a3b8; line-height: 1.6; margin-bottom: 24px; }
    a.btn { display: inline-block; background: #ef4444; color: #fff; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">✓ VERIFIED</span>
    <h1>Email Confirmed!</h1>
    <p>Your B2WIN account is now verified. You can return to the B2WIN mobile app or web portal and sign in.</p>
    <a href="/" class="btn">Return to B2WIN</a>
  </div>
</body>
</html>`);
};

/**
 * POST /api/v1/users/forgot-password
 * Sends a Supabase Auth password reset email.
 */
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: "Email is required" });
  }

  try {
    const authClient = supabase.createAuthClient();
    const { error } = await authClient.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      { redirectTo: getDefaultConfirmRedirect(req) }
    );

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(200).json({
      success: true,
      message: "Password reset instructions have been sent to your email.",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * GET /api/v1/users/oauth/google
 * Generates a Supabase Google OAuth sign-in URL (or redirects directly when ?redirect=true)
 */
exports.getGoogleOAuthUrl = async (req, res) => {
  try {
    const redirectTo =
      req.query.redirectTo || getDefaultConfirmRedirect(req);
    const authClient = supabase.createAuthClient();

    const { data, error } = await authClient.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo,
        queryParams: {
          access_type: "offline",
          prompt: "consent",
        },
      },
    });

    if (error || !data?.url) {
      return res.status(400).json({
        error: error?.message || "Failed to generate Google OAuth URL",
      });
    }

    if (req.query.redirect === "true") {
      return res.redirect(data.url);
    }

    res.status(200).json({ url: data.url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

/**
 * POST /api/v1/users/oauth/google
 * Exchanges either:
 *   1. Native Google { idToken, accessToken } via supabase.auth.signInWithIdToken, OR
 *   2. Supabase OAuth callback { accessToken, refreshToken }
 * and syncs the user into public.profiles.
 */
exports.googleOAuthLogin = async (req, res) => {
  const { idToken, accessToken, refreshToken } = req.body;

  if (!idToken && !accessToken) {
    return res.status(400).json({
      error: "idToken or accessToken is required for Google Sign-In",
    });
  }

  try {
    const authClient = supabase.createAuthClient();
    let authUser = null;
    let finalToken = accessToken || null;
    let finalRefresh = refreshToken || null;

    if (idToken) {
      const { data, error } = await authClient.auth.signInWithIdToken({
        provider: "google",
        token: idToken,
        access_token: accessToken,
      });

      if (error || !data?.user || !data?.session) {
        return res.status(401).json({
          error: error?.message || "Google ID token verification failed",
        });
      }

      authUser = data.user;
      finalToken = data.session.access_token;
      finalRefresh = data.session.refresh_token;
    } else {
      const { data, error } = await supabase.auth.getUser(accessToken);
      if (error || !data?.user) {
        return res.status(401).json({
          error: error?.message || "Invalid Supabase OAuth access token",
        });
      }
      authUser = data.user;
    }

    const profile = await ensureProfileForAuthUser(authUser);

    res.status(200).json({
      token: finalToken,
      refreshToken: finalRefresh,
      user: mapUser(profile),
    });
  } catch (err) {
    console.error("Google OAuth login error:", err);
    res.status(500).json({ error: "Google Sign-In failed" });
  }
};

exports.loginUser = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  const emailClean = email.trim().toLowerCase();
  const authClient = supabase.createAuthClient();

  try {
    // 1. Fetch profile from public.profiles
    let { data: profile } = await supabase
      .from("profiles")
      .select("*")
      .ilike("email", emailClean)
      .maybeSingle();

    // 2. Attempt native Supabase Auth sign-in
    let { data: signInData, error: signInError } =
      await authClient.auth.signInWithPassword({
        email: emailClean,
        password,
      });

    // If Supabase specifically says "Email not confirmed", return a clear status
    if (
      signInError &&
      signInError.message &&
      signInError.message.toLowerCase().includes("email not confirmed")
    ) {
      return res.status(403).json({
        error:
          "Please confirm your email address before signing in. Check your inbox or request a new confirmation link.",
        emailNotConfirmed: true,
      });
    }

    // 3. Lazy-migration path for MongoDB-migrated users
    if (signInError && profile && profile.password_hash) {
      let isLegacyMatch = false;
      try {
        isLegacyMatch = await bcrypt.compare(password, profile.password_hash);
      } catch (_) {
        isLegacyMatch = false;
      }

      if (isLegacyMatch) {
        const isAdmin = Boolean(profile.is_admin);
        const existingAuthUser = await findAuthUserByEmailOrId(
          profile.id,
          emailClean
        );

        if (existingAuthUser) {
          await supabase.auth.admin.updateUserById(existingAuthUser.id, {
            password,
            email_confirm: true,
            user_metadata: { username: profile.username },
            app_metadata: {
              role: isAdmin ? "admin" : "user",
              is_admin: isAdmin,
            },
          });
        } else {
          await supabase.auth.admin.createUser({
            id: profile.id,
            email: emailClean,
            password,
            email_confirm: true,
            user_metadata: { username: profile.username },
            app_metadata: {
              role: isAdmin ? "admin" : "user",
              is_admin: isAdmin,
            },
          });
        }

        const retryResult = await authClient.auth.signInWithPassword({
          email: emailClean,
          password,
        });
        signInData = retryResult.data;
        signInError = retryResult.error;
      }
    }

    if (signInError || !signInData?.session || !signInData?.user) {
      return res.status(400).json({ error: "Invalid Credentials" });
    }

    const { session, user: authUser } = signInData;

    if (!profile) {
      profile = await ensureProfileForAuthUser(authUser);
    }

    res.json({
      token: session.access_token,
      refreshToken: session.refresh_token,
      expiresIn: session.expires_in,
      user: mapUser(profile),
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ error: "Login failed" });
  }
};

exports.refreshToken = async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ error: "refreshToken is required" });
  }

  try {
    const authClient = supabase.createAuthClient();
    const { data, error } = await authClient.auth.refreshSession({
      refresh_token: refreshToken,
    });

    if (error || !data?.session) {
      return res
        .status(401)
        .json({ error: "Invalid or expired refresh token" });
    }

    res.status(200).json({
      token: data.session.access_token,
      refreshToken: data.session.refresh_token,
      expiresIn: data.session.expires_in,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.logoutUser = async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.split(" ")[1]
      : null;

    if (token) {
      await supabase.auth.admin.signOut(token);
    }

    res.status(200).json({
      success: true,
      message: "Logged out successfully",
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.getMe = async (req, res) => {
  res.status(200).json({
    success: true,
    user: req.user,
  });
};

exports.fetchUsers = async (req, res) => {
  try {
    const { data: users, error } = await supabase
      .from("profiles")
      .select("id, email, username, is_admin, created_at")
      .order("created_at", { ascending: false });

    if (error) {
      return res.status(500).json({ success: false, error: error.message });
    }

    res.status(200).json({
      success: true,
      data: users.map(mapUser),
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.updateUserRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { isAdmin } = req.body;

    if (typeof isAdmin !== "boolean") {
      return res.status(400).json({
        success: false,
        error: "isAdmin boolean field is required in request body",
      });
    }

    if (req.user && req.user.id === id && isAdmin === false) {
      return res.status(400).json({
        success: false,
        error: "Admins cannot revoke their own admin privileges",
      });
    }

    const { data: updatedUser, error } = await supabase
      .from("profiles")
      .update({ is_admin: isAdmin })
      .eq("id", id)
      .select("id, email, username, is_admin, created_at")
      .maybeSingle();

    if (error || !updatedUser) {
      return res.status(404).json({
        success: false,
        error: "User not found",
      });
    }

    const authUser = await findAuthUserByEmailOrId(
      updatedUser.id,
      updatedUser.email
    );
    if (authUser) {
      await supabase.auth.admin.updateUserById(authUser.id, {
        app_metadata: {
          ...authUser.app_metadata,
          role: isAdmin ? "admin" : "user",
          is_admin: isAdmin,
        },
      });
    }

    res.status(200).json({
      success: true,
      message: `User role updated to ${isAdmin ? "admin" : "regular user"}`,
      user: mapUser(updatedUser),
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};
