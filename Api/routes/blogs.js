const express = require("express");
const {
  createBlog,
  getAllBlogs,
  getBlogById,
  updateBlog,
  deleteBlog,
} = require("../controllers/blogs");

const router = express.Router({ mergeParams: true });

router.route("/").get(getAllBlogs).post(createBlog);

router.route("/:id").get(getBlogById).put(updateBlog).delete(deleteBlog);

module.exports = router;
