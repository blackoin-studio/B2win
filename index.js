const express = require("express");
const dotenv = require("dotenv").config({ path: "./config.env" });

const mongoose = require("mongoose");

// const connectDB = require("./db");
//Initialize DB
//connectDB();
const app = express();

mongoose.connect(process.env.MONGODB_URI, {
  dbName: "b2win",
});

const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  username: { type: String, required: true, unique: true }, // New username field
});
const User = mongoose.model("User", UserSchema);

app.use(express.json());

app.post("/register", async (req, res) => {
  const { email, password, username } = req.body;

  const existingUser = await User.findOne({ $or: [{ email }, { username }] });
  if (existingUser) {
    return res.status(400).json({ error: "Email or username already exists" });
  }

  // const hashedPassword = await bcrypt.hash(password, 10);
  const newUser = new User({ email, password, username });

  try {
    await newUser.save();
    res.status(201).json({ message: "User registered successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to register user" });
  }
});

const PORT = process.env.PORT || 5000;
const server = app.listen(
  PORT,
  console.log(`server running in ${process.env.NODE_ENV} mode on port:`, PORT)
);
