const Blog = require("../models/Blog");
const upload = require("../utils/uploadSingle");

// Create Blog
exports.createBlog = (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      return res
        .status(400)
        .json({ message: "Error uploading file", error: err.message });
    }

    try {
      const { title, description } = req.body;

      // If logos are uploaded, use the file paths; else use default logos
      // Get the uploaded image file paths

      const photo = req.file ? `${req.file.filename}` : "no-away-photo.jpg";

      const newBlog = new Blog({
        title,
        description,
        photo,
      });

      await newBlog.save(); // Save Blog to the database

      res.status(201).json(newBlog); // Respond with the created Blog
    } catch (error) {
      res.status(500).json({ message: "Error creating Blog", error });
    }
  });
};

// Get all Blogs
exports.getAllBlogs = async (req, res) => {
  try {
    const Blogs = await Blog.find({});
    res.status(200).json(Blogs);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching Blogs", error: error.message });
  }
};

// Get a specific Blog by ID
exports.getBlogById = async (req, res) => {
  try {
    const Blog = await Blog.findById(req.params.id);
    if (!Blog) {
      return res.status(404).json({ message: "Blog not found" });
    }
    res.status(200).json(Blog);
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching Blog", error: error.message });
  }
};

// Update a Blog by ID
exports.updateBlog = async (req, res) => {
  try {
    const { date, title, description, photo } = req.body;

    const updatedBlog = await Blog.findByIdAndUpdate(
      req.params.id,
      {
        date,
        title,
        description,
        photo,
      },
      { new: true }
    );

    if (!updatedBlog) {
      return res.status(404).json({ message: "Blog not found" });
    }

    res.status(200).json({
      message: "Blog updated successfully",
      Blog: updatedBlog,
    });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error updating Blog", error: error.message });
  }
};

// Delete a Blog by ID
exports.deleteBlog = async (req, res) => {
  try {
    const deletedBlog = await Blog.findByIdAndDelete(req.params.id);
    if (!deletedBlog) {
      return res.status(404).json({ message: "Blog not found" });
    }
    res.status(200).json({ message: "Blog deleted successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error deleting Blog", error: error.message });
  }
};
