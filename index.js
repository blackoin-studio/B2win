const express = require("express");
const dotenv = require("dotenv").config({ path: "./config.env" });
const mongoose = require("mongoose");
const connectDB = require("./Api/utils/db");
const users = require("./Api/routes/users");

//Initialize DB
connectDB();

const app = express();

app.use(express.json());

app.use("/api/v1/users", users);

const PORT = process.env.PORT || 5000;
const server = app.listen(
  PORT,
  console.log(`server running in ${process.env.NODE_ENV} mode on port:`, PORT)
);
