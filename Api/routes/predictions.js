const express = require("express");
const {
  createPrediction,
  getAllPredictions,
  getPredictionById,
  updatePrediction,
  deletePrediction,
} = require("../controllers/predictions");
const { protect, adminOnly } = require("../middleware/auth");

const router = express.Router({ mergeParams: true });

router
  .route("/")
  .get(getAllPredictions)
  .post(protect, adminOnly, createPrediction);

router
  .route("/:id")
  .get(getPredictionById)
  .put(protect, adminOnly, updatePrediction)
  .delete(protect, adminOnly, deletePrediction);

module.exports = router;
