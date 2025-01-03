const User = require("../models/User");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");

const JWT_SECRET = process.env.JWT_SECRET;

exports.registerUser = async (req, res) => {
  const { email, password, username } = req.body;

  const existingUser = await User.findOne({ $or: [{ email }, { username }] });
  if (existingUser) {
    return res.status(400).json({ error: "Email or Username already exists" });
  }

  try {
    await User.create(req.body);
    console.log("User registered nwayoly");
    res.status(201).json({ message: "User registered successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to register user" });
  }
};

exports.loginUser = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user || !(await bcrypt.compare(password, user.password)))
    return res.status(400).json({ error: "Invalid Credentials" });

  const token = jwt.sign({ id: user._id }, JWT_SECRET, { expiresIn: "24h" });
  console.log(token);
  res.json({ token });
};

exports.fetchUsers = async (req, res) => {
  const user = await User.find({});

  res.status(200).json({
    success: true,
    data: user,
  });
};
