const express = require("express");
const fs = require("fs");
const path = require("path");
const dotenv = require("dotenv").config({ path: "./config.env" });
const mongoose = require("mongoose");
const connectDB = require("./Api/utils/db");
const users = require("./Api/routes/users");
const blogs = require("./Api/routes/blogs");
const predictions = require("./Api/routes/predictions");

//Initialize DB
connectDB();

const app = express();

app.use(express.json());

const uploadDir = path.join(__dirname, "public");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

app.use("/public", express.static("./public"));
app.use("/", express.static("./public"));

app.use("/api/v1/users", users);
app.use("/api/v1/blogs", blogs);
app.use("/api/v1/predictions", predictions);

// render Landing Page
// app.get("/", function (req, res) {
//   res.sendFile("./public/index.html");
// });

const PORT = process.env.PORT || 5000;
const server = app.listen(
  PORT,
  console.log(`server running in ${process.env.NODE_ENV} mode on port:`, PORT)
);
