const multer = require("multer");
const path = require("path");

// Use memory storage so files can be streamed directly to Supabase Storage
const storage = multer.memoryStorage();

const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png|gif|webp/;
    const extname = filetypes.test(
      path.extname(file.originalname).toLowerCase()
    );
    const mimetype = filetypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error("Only image files (jpg, png, gif, webp) are allowed"));
    }
  },
}).fields([
  { name: "leagueLogo", maxCount: 1 },
  { name: "homeLogo", maxCount: 1 },
  { name: "awayLogo", maxCount: 1 },
]);

module.exports = upload;
