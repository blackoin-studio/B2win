const express = require("express");
const fs = require("fs");
const path = require("path");
const dotenv = require("dotenv").config({ path: "./config.env" });
const users = require("./Api/routes/users");
const blogs = require("./Api/routes/blogs");
const predictions = require("./Api/routes/predictions");

const app = express();

// Enable CORS for dedicated AdminFrontend & Mobile clients
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", req.headers.origin || "*");
  res.header(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  );
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept, Authorization, x-auth-token"
  );
  if (req.method === "OPTIONS") {
    return res.sendStatus(204);
  }
  next();
});

app.use(express.json());

const uploadDir = path.resolve(__dirname, "public");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

const adminDistDir = path.resolve(__dirname, "AdminFrontend", "dist");

app.use("/public", express.static(uploadDir));
app.use("/admin", express.static(adminDistDir));
app.use("/", express.static(uploadDir));

app.use("/api/v1/users", users);
app.use("/api/v1/blogs", blogs);
app.use("/api/v1/predictions", predictions);

// Render Dedicated React Admin Dashboard at /admin
app.get(["/admin", "/admin/*"], (req, res) => {
  const adminIndex = path.join(adminDistDir, "index.html");
  if (fs.existsSync(adminIndex)) {
    return res.sendFile("index.html", { root: adminDistDir });
  }
  return res
    .status(503)
    .send("AdminFrontend build not found. Run: npm run build");
});

// Render Public Landing Page at /
app.get("/", (req, res) => {
  res.sendFile("index.html", { root: uploadDir });
});

const PORT = process.env.PORT || 5000;
const server = app.listen(
  PORT,
  console.log(`server running in ${process.env.NODE_ENV} mode on port:`, PORT)
);
