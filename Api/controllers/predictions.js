const Prediction = require("../models/Prediction");
const upload = require("../utils/upload");

// Create Prediction
exports.createPrediction = (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      return res
        .status(400)
        .json({ message: "Error uploading file", error: err.message });
    }

    try {
      const { time, league, homeTeam, awayTeam, score, odds, status, tip } =
        req.body;

      // If logos are uploaded, use the file paths; else use default logos
      // Get the uploaded image file paths
      const leagueLogo = req.files["leagueLogo"]
        ? `/uploads/${req.files["leagueLogo"][0].filename}`
        : "no-league-photo.jpg";
      const homeLogo = req.files["homeLogo"]
        ? `/uploads/${req.files["homeLogo"][0].filename}`
        : "no-home-photo.jpg";
      const awayLogo = req.files["awayLogo"]
        ? `/uploads/${req.files["awayLogo"][0].filename}`
        : "no-away-photo.jpg";

      const newPrediction = new Prediction({
        time,
        league,
        homeTeam,
        awayTeam,
        score,
        odds,
        status,
        tip,
        homeLogo,
        awayLogo,
        leagueLogo,
      });

      await newPrediction.save(); // Save prediction to the database

      res.status(201).json(newPrediction); // Respond with the created prediction
    } catch (error) {
      res.status(500).json({ message: "Error creating prediction", error });
    }
  });
};

// Get all predictions
exports.getAllPredictions = async (req, res) => {
  try {
    const predictions = await Prediction.find({});
    res.status(200).json(predictions);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching predictions", error: error.message });
  }
};

// Get a specific prediction by ID
exports.getPredictionById = async (req, res) => {
  try {
    const prediction = await Prediction.findById(req.params.id);
    if (!prediction) {
      return res.status(404).json({ message: "Prediction not found" });
    }
    res.status(200).json(prediction);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching prediction", error: error.message });
  }
};

// Update a prediction by ID
exports.updatePrediction = async (req, res) => {
  try {
    const {
      date,
      time,
      league,
      homeTeam,
      awayTeam,
      leagueLogo,
      homeLogo,
      awayLogo,
      score,
      odds,
      status,
      tip,
    } = req.body;

    const updatedPrediction = await Prediction.findByIdAndUpdate(
      req.params.id,
      {
        date,
        time,
        league,
        homeTeam,
        awayTeam,
        leagueLogo,
        homeLogo,
        awayLogo,
        score,
        odds,
        status,
        tip,
      },
      { new: true }
    );

    if (!updatedPrediction) {
      return res.status(404).json({ message: "Prediction not found" });
    }

    res
      .status(200)
      .json({
        message: "Prediction updated successfully",
        prediction: updatedPrediction,
      });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error updating prediction", error: error.message });
  }
};

// Delete a prediction by ID
exports.deletePrediction = async (req, res) => {
  try {
    const deletedPrediction = await Prediction.findByIdAndDelete(req.params.id);
    if (!deletedPrediction) {
      return res.status(404).json({ message: "Prediction not found" });
    }
    res.status(200).json({ message: "Prediction deleted successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error deleting prediction", error: error.message });
  }
};
