const express = require("express");
const { registerUser, fetchUsers } = require("../controllers/users");

const router = express.Router({ mergeParams: true });

router.route("/").get(fetchUsers);
router.route("/register").post(registerUser);

module.exports = router;
