const express = require("express");
const {
  createBlog,
  getAllBlogs,
  getBlogById,
  updateBlog,
  deleteBlog,
} = require("../controllers/blogs");
const { protect, adminOnly } = require("../middleware/auth");

const router = express.Router({ mergeParams: true });

router
  .route("/")
  .get(getAllBlogs)
  .post(protect, adminOnly, createBlog);

router
  .route("/:id")
  .get(getBlogById)
  .put(protect, adminOnly, updateBlog)
  .delete(protect, adminOnly, deleteBlog);

module.exports = router;
