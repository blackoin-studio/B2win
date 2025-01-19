const express = require("express");
const {
  createPrediction,
  getAllPredictions,
  getPredictionById,
  updatePrediction,
  deletePrediction,
} = require("../controllers/predictions");

const router = express.Router({ mergeParams: true });

router.route("/").get(getAllPredictions).post(createPrediction);

router
  .route("/:id")
  .get(getPredictionById)
  .put(updatePrediction)
  .delete(deletePrediction);

module.exports = router;
