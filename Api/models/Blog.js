const mongoose = require("mongoose");

const BlogSchema = new mongoose.Schema({
  date: {
    type: Date,
    default: Date.now,
  },
  title: {
    type: String,
  },
  description: {
    type: String,
  },
  photo: {
    type: String,
    default: "no-league-photo.jpg",
  },
});

module.exports = mongoose.model("Blog", BlogSchema);
