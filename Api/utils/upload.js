const multer = require("multer");
const path = require("path");

// Define storage location and filename for uploaded files
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // Save files to the "uploads" directory
  },
  filename: (req, file, cb) => {
    cb(null, file.originalname + Date.now() + path.extname(file.originalname)); // Use current timestamp to avoid name collisions
  },
});

// Create multer instance for uploading files
const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // Limit file size to 5 MB
  fileFilter: (req, file, cb) => {
    // Allow only image files
    const filetypes = /jpeg|jpg|png|gif/;
    const extname = filetypes.test(
      path.extname(file.originalname).toLowerCase()
    );
    const mimetype = filetypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"));
    }
  },
}).fields([
  { name: "leagueLogo", maxCount: 1 },
  { name: "homeLogo", maxCount: 1 },
  { name: "awayLogo", maxCount: 1 },
]); // The field name for the uploaded file (e.g., 'logo')

// Export the upload middleware for use in routes
module.exports = upload;
