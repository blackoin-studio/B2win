const express = require("express");
const {
  registerUser,
  resendConfirmation,
  confirmEmailCallback,
  forgotPassword,
  getGoogleOAuthUrl,
  googleOAuthLogin,
  loginUser,
  refreshToken,
  logoutUser,
  getMe,
  fetchUsers,
  updateUserRole,
} = require("../controllers/users");
const { protect, adminOnly } = require("../middleware/auth");

const router = express.Router({ mergeParams: true });

// Public Supabase Auth routes
router.route("/register").post(registerUser);
router.route("/resend-confirmation").post(resendConfirmation);
router.route("/confirm").get(confirmEmailCallback);
router.route("/forgot-password").post(forgotPassword);
router.route("/oauth/google").get(getGoogleOAuthUrl).post(googleOAuthLogin);
router.route("/login").post(loginUser);
router.route("/refresh").post(refreshToken);

// Authenticated user routes
router.route("/me").get(protect, getMe);
router.route("/logout").post(protect, logoutUser);

// Admin-protected user management routes
router.route("/").get(protect, adminOnly, fetchUsers);
router.route("/:id/role").patch(protect, adminOnly, updateUserRole);

module.exports = router;
