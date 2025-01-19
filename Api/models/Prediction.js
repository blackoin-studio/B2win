const mongoose = require("mongoose");

const PredictionSchema = new mongoose.Schema({
  date: {
    type: Date,
    default: Date.now,
  },
  time: {
    type: String,
  },
  league: {
    type: String,
  },
  homeTeam: {
    type: String,
  },
  awayTeam: {
    type: String,
  },
  leagueLogo: {
    type: String,
    default: "no-league-photo.jpg",
  },
  homeLogo: {
    type: String,
    default: "no-home-photo.jpg",
  },
  awayLogo: {
    type: String,
    default: "no-away-photo.jpg",
  },
  score: {
    type: String,
  },
  odds: {
    type: String,
  },
  status: {
    type: String,
    default: "pending",
  },
  tip: {
    type: String,
  },
});

module.exports = mongoose.model("Prediction", PredictionSchema);
