const express = require("express");
const fs = require("fs");
const path = require("path");
const dotenv = require("dotenv").config({ path: "./config.env" });
const mongoose = require("mongoose");
const connectDB = require("./Api/utils/db");
const users = require("./Api/routes/users");
const predictions = require("./Api/routes/predictions");

//Initialize DB
connectDB();

const app = express();

app.use(express.json());

const uploadDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

app.use("./uploads", express.static("uploads"));

app.use("/api/v1/users", users);
app.use("/api/v1/predictions", predictions);

const PORT = process.env.PORT || 5000;
const server = app.listen(
  PORT,
  console.log(`server running in ${process.env.NODE_ENV} mode on port:`, PORT)
);
