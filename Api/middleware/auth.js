const jwt = require("jsonwebtoken");
const supabase = require("../utils/supabase");

const JWT_SECRET = process.env.JWT_SECRET || "default_secret";

/**
 * Middleware: Verify Supabase Auth access token (with legacy JWT fallback)
 * and attach current user profile to req.user
 */
exports.protect = async (req, res, next) => {
  try {
    let token;

    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith("Bearer ")
    ) {
      token = req.headers.authorization.split(" ")[1];
    } else if (req.headers["x-auth-token"]) {
      token = req.headers["x-auth-token"];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        error: "Not authorized: No authentication token provided",
      });
    }

    // 1. Primary path: Verify token via Supabase Auth
    const {
      data: { user: authUser },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (!authError && authUser) {
      // Look up profile by id first, or fallback to email (for migrated profiles)
      let { data: profile } = await supabase
        .from("profiles")
        .select("id, email, username, is_admin, created_at")
        .eq("id", authUser.id)
        .maybeSingle();

      if (!profile && authUser.email) {
        const { data: profileByEmail } = await supabase
          .from("profiles")
          .select("id, email, username, is_admin, created_at")
          .ilike("email", authUser.email)
          .maybeSingle();
        profile = profileByEmail;
      }

      const isAdmin =
        Boolean(profile?.is_admin) ||
        Boolean(authUser.app_metadata?.is_admin) ||
        authUser.app_metadata?.role === "admin";

      req.user = {
        _id: profile ? profile.id : authUser.id,
        id: profile ? profile.id : authUser.id,
        authId: authUser.id,
        email: profile ? profile.email : authUser.email,
        username:
          profile?.username ||
          authUser.user_metadata?.username ||
          (authUser.email ? authUser.email.split("@")[0] : "user"),
        isAdmin,
        createdAt: profile ? profile.created_at : authUser.created_at,
      };

      return next();
    }

    // 2. Fallback path: Legacy custom JWT verification (backward compatibility)
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return res.status(401).json({
        success: false,
        error: "Not authorized: Invalid or expired token",
      });
    }

    const { data: user, error: dbError } = await supabase
      .from("profiles")
      .select("id, email, username, is_admin, created_at")
      .eq("id", decoded.id)
      .maybeSingle();

    if (dbError || !user) {
      return res.status(401).json({
        success: false,
        error: "Not authorized: User no longer exists",
      });
    }

    req.user = {
      _id: user.id,
      id: user.id,
      email: user.email,
      username: user.username,
      isAdmin: Boolean(user.is_admin),
      createdAt: user.created_at,
    };

    next();
  } catch (err) {
    console.error("[Auth Middleware] Error:", err);
    return res.status(500).json({
      success: false,
      error: "Server error during authentication",
    });
  }
};

/**
 * Middleware: Require authenticated user to have is_admin === true
 * Must be used after `protect` middleware.
 */
exports.adminOnly = (req, res, next) => {
  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({
      success: false,
      error: "Forbidden: Admin privileges required",
    });
  }
  next();
};
