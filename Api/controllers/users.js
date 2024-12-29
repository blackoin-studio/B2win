const User = require("../models/User");

exports.registerUser = async (req, res) => {
  const { email, password, username } = req.body;

  const existingUser = await User.findOne({ $or: [{ email }, { username }] });
  if (existingUser) {
    return res.status(400).json({ error: "Email or Username already exists" });
  }

  // const hashedPassword = await bcrypt.hash(password, 10);
  // const newUser = new User({ email, password, username });

  try {
    await User.create(req.body); //newUser.save();
    console.log("User registered nwayoly");
    res.status(201).json({ message: "User registered successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to register user" });
  }
};

exports.fetchUsers = async (req, res) => {
  const user = await User.find({});

  res.status(200).json({
    success: true,
    data: user,
  });
};
