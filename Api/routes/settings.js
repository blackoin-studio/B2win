const express = require("express");
const { getAdSettings, updateAdSettings } = require("../controllers/settings");
const { protect, adminOnly } = require("../middleware/auth");

const router = express.Router();

// Public: Mobile app fetches whether ads are enabled and which Ad Unit IDs to use
router.route("/ads").get(getAdSettings);

// Admin Only: Toggle Google Ads ON/OFF and update AdMob Unit IDs / placements
router.route("/ads").put(protect, adminOnly, updateAdSettings);

module.exports = router;

