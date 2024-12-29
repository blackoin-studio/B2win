const express = require("express");
const { registerUser, loginUser, fetchUsers } = require("../controllers/users");

const router = express.Router({ mergeParams: true });

router.route("/").get(fetchUsers);
router.route("/register").post(registerUser);
router.route("/login").get(loginUser);

module.exports = router;
