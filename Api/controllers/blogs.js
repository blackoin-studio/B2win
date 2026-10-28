const supabase = require("../utils/supabase");
const upload = require("../utils/uploadSingle");
const { uploadFileToSupabase } = require("../utils/supabaseStorage");

const mapBlog = (blog) => ({
  _id: blog.id,
  id: blog.id,
  title: blog.title,
  description: blog.description,
  photo: blog.photo,
  date: blog.date,
  createdAt: blog.created_at,
  updatedAt: blog.updated_at,
});

// Create Blog (Uploads cover image to Supabase Storage)
exports.createBlog = (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      return res
        .status(400)
        .json({ message: "Error uploading file", error: err.message });
    }

    try {
      const { title, description } = req.body;
      let photo = "no-away-photo.jpg";

      if (req.file) {
        photo = await uploadFileToSupabase(req.file, "blogs");
      }

      const { data: newBlog, error } = await supabase
        .from("blogs")
        .insert({
          title: title || "Untitled Blog",
          description: description || "",
          photo,
        })
        .select()
        .single();

      if (error) {
        return res
          .status(500)
          .json({ message: "Error creating Blog", error: error.message });
      }

      res.status(201).json(mapBlog(newBlog));
    } catch (error) {
      res
        .status(500)
        .json({ message: "Error creating Blog", error: error.message });
    }
  });
};

// Get all Blogs
exports.getAllBlogs = async (req, res) => {
  try {
    const { data: blogs, error } = await supabase
      .from("blogs")
      .select("*")
      .order("date", { ascending: false });

    if (error) {
      return res
        .status(500)
        .json({ message: "Error fetching Blogs", error: error.message });
    }

    res.status(200).json((blogs || []).map(mapBlog));
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching Blogs", error: error.message });
  }
};

// Get a specific Blog by ID
exports.getBlogById = async (req, res) => {
  try {
    const { data: blog, error } = await supabase
      .from("blogs")
      .select("*")
      .eq("id", req.params.id)
      .maybeSingle();

    if (error || !blog) {
      return res.status(404).json({ message: "Blog not found" });
    }

    res.status(200).json(mapBlog(blog));
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching Blog", error: error.message });
  }
};

// Update a Blog by ID (Supports both JSON body and multipart FormData cover image update)
exports.updateBlog = (req, res) => {
  const isMultipart = (req.headers["content-type"] || "").includes(
    "multipart/form-data"
  );

  const handleUpdate = async () => {
    try {
      const { date, title, description, photo } = req.body;
      const updatePayload = {};

      if (date !== undefined) updatePayload.date = date;
      if (title !== undefined) updatePayload.title = title;
      if (description !== undefined) updatePayload.description = description;
      if (photo !== undefined) updatePayload.photo = photo;

      if (req.file) {
        updatePayload.photo = await uploadFileToSupabase(req.file, "blogs");
      }

      const { data: updatedBlog, error } = await supabase
        .from("blogs")
        .update(updatePayload)
        .eq("id", req.params.id)
        .select()
        .maybeSingle();

      if (error || !updatedBlog) {
        return res.status(404).json({ message: "Blog not found" });
      }

      res.status(200).json({
        message: "Blog updated successfully",
        Blog: mapBlog(updatedBlog),
      });
    } catch (error) {
      res
        .status(500)
        .json({ message: "Error updating Blog", error: error.message });
    }
  };

  if (isMultipart) {
    upload(req, res, (err) => {
      if (err) {
        return res
          .status(400)
          .json({ message: "Error uploading file", error: err.message });
      }
      handleUpdate();
    });
  } else {
    handleUpdate();
  }
};

// Delete a Blog by ID
exports.deleteBlog = async (req, res) => {
  try {
    const { data: deletedBlog, error } = await supabase
      .from("blogs")
      .delete()
      .eq("id", req.params.id)
      .select("id")
      .maybeSingle();

    if (error || !deletedBlog) {
      return res.status(404).json({ message: "Blog not found" });
    }

    res.status(200).json({ message: "Blog deleted successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error deleting Blog", error: error.message });
  }
};
