const express = require("express");
const {
  getOverviewInsights,
  generateAiBlog,
  autofillPrediction,
  getMatchInsight,
  generateSmartSlip,
  summarizeBlog,
  chatWithAiTipster,
} = require("../controllers/ai");
const { protect, adminOnly } = require("../middleware/auth");

const router = express.Router();

// Admin Panel AI Endpoints
router.get("/overview-insights", protect, adminOnly, getOverviewInsights);
router.post("/generate-blog", protect, adminOnly, generateAiBlog);
router.post("/autofill-prediction", protect, adminOnly, autofillPrediction);

// Mobile App User-Facing AI Endpoints
router.post("/match-insight", getMatchInsight);
router.post("/smart-slip", generateSmartSlip);
router.post("/blog-summary", summarizeBlog);
router.post("/chat", chatWithAiTipster);

module.exports = router;

