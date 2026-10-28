const supabase = require("../utils/supabase");
const upload = require("../utils/upload");
const { uploadFileToSupabase } = require("../utils/supabaseStorage");

const VALID_STATUSES = ["pending", "won", "lost", "postponed", "cancelled"];

function normalizeStatus(status) {
  if (!status) return "pending";
  const lower = status.toString().trim().toLowerCase();
  return VALID_STATUSES.includes(lower) ? lower : "pending";
}

const mapPrediction = (p) => ({
  _id: p.id,
  id: p.id,
  date: p.date,
  time: p.time,
  league: p.league,
  homeTeam: p.home_team,
  awayTeam: p.away_team,
  leagueLogo: p.league_logo,
  homeLogo: p.home_logo,
  awayLogo: p.away_logo,
  score: p.score,
  odds: p.odds,
  status: p.status,
  tip: p.tip,
  createdAt: p.created_at,
  updatedAt: p.updated_at,
});

// Create Prediction (Uploads logos to Supabase Storage)
exports.createPrediction = (req, res) => {
  upload(req, res, async (err) => {
    if (err) {
      return res
        .status(400)
        .json({ message: "Error uploading file", error: err.message });
    }

    try {
      const {
        time,
        league,
        homeTeam,
        awayTeam,
        score,
        odds,
        status,
        tip,
        date,
      } = req.body;

      let leagueLogo = "no-league-photo.jpg";
      let homeLogo = "no-home-photo.jpg";
      let awayLogo = "no-away-photo.jpg";

      if (req.files) {
        if (req.files["leagueLogo"]?.[0]) {
          leagueLogo = await uploadFileToSupabase(
            req.files["leagueLogo"][0],
            "predictions"
          );
        }
        if (req.files["homeLogo"]?.[0]) {
          homeLogo = await uploadFileToSupabase(
            req.files["homeLogo"][0],
            "predictions"
          );
        }
        if (req.files["awayLogo"]?.[0]) {
          awayLogo = await uploadFileToSupabase(
            req.files["awayLogo"][0],
            "predictions"
          );
        }
      }

      const { data: newPrediction, error } = await supabase
        .from("predictions")
        .insert({
          date: date || new Date(),
          time: time || "00:00",
          league: league || "Unknown League",
          home_team: homeTeam || "Home Team",
          away_team: awayTeam || "Away Team",
          score: score || "-",
          odds: odds ? String(odds) : "1.00",
          status: normalizeStatus(status),
          tip: tip || "N/A",
          home_logo: homeLogo,
          away_logo: awayLogo,
          league_logo: leagueLogo,
        })
        .select()
        .single();

      if (error) {
        return res
          .status(500)
          .json({ message: "Error creating prediction", error: error.message });
      }

      res.status(201).json(mapPrediction(newPrediction));
    } catch (error) {
      res
        .status(500)
        .json({ message: "Error creating prediction", error: error.message });
    }
  });
};

// Get all predictions
exports.getAllPredictions = async (req, res) => {
  try {
    const { data: predictions, error } = await supabase
      .from("predictions")
      .select("*")
      .order("date", { ascending: false });

    if (error) {
      return res
        .status(500)
        .json({ message: "Error fetching predictions", error: error.message });
    }

    res.status(200).json((predictions || []).map(mapPrediction));
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching predictions", error: error.message });
  }
};

// Get a specific prediction by ID
exports.getPredictionById = async (req, res) => {
  try {
    const { data: prediction, error } = await supabase
      .from("predictions")
      .select("*")
      .eq("id", req.params.id)
      .maybeSingle();

    if (error || !prediction) {
      return res.status(404).json({ message: "Prediction not found" });
    }

    res.status(200).json(mapPrediction(prediction));
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error fetching prediction", error: error.message });
  }
};

// Update a prediction by ID (Supports both JSON body and multipart FormData logo updates)
exports.updatePrediction = (req, res) => {
  const isMultipart = (req.headers["content-type"] || "").includes(
    "multipart/form-data"
  );

  const handleUpdate = async () => {
    try {
      const {
        date,
        time,
        league,
        homeTeam,
        awayTeam,
        leagueLogo,
        homeLogo,
        awayLogo,
        score,
        odds,
        status,
        tip,
      } = req.body;

      const updatePayload = {};
      if (date !== undefined) updatePayload.date = date;
      if (time !== undefined) updatePayload.time = time;
      if (league !== undefined) updatePayload.league = league;
      if (homeTeam !== undefined) updatePayload.home_team = homeTeam;
      if (awayTeam !== undefined) updatePayload.away_team = awayTeam;
      if (leagueLogo !== undefined) updatePayload.league_logo = leagueLogo;
      if (homeLogo !== undefined) updatePayload.home_logo = homeLogo;
      if (awayLogo !== undefined) updatePayload.away_logo = awayLogo;
      if (score !== undefined) updatePayload.score = score;
      if (odds !== undefined) updatePayload.odds = String(odds);
      if (status !== undefined) updatePayload.status = normalizeStatus(status);
      if (tip !== undefined) updatePayload.tip = tip;

      if (req.files) {
        if (req.files["leagueLogo"]?.[0]) {
          updatePayload.league_logo = await uploadFileToSupabase(
            req.files["leagueLogo"][0],
            "predictions"
          );
        }
        if (req.files["homeLogo"]?.[0]) {
          updatePayload.home_logo = await uploadFileToSupabase(
            req.files["homeLogo"][0],
            "predictions"
          );
        }
        if (req.files["awayLogo"]?.[0]) {
          updatePayload.away_logo = await uploadFileToSupabase(
            req.files["awayLogo"][0],
            "predictions"
          );
        }
      }

      const { data: updatedPrediction, error } = await supabase
        .from("predictions")
        .update(updatePayload)
        .eq("id", req.params.id)
        .select()
        .maybeSingle();

      if (error || !updatedPrediction) {
        return res.status(404).json({ message: "Prediction not found" });
      }

      res.status(200).json({
        message: "Prediction updated successfully",
        prediction: mapPrediction(updatedPrediction),
      });
    } catch (error) {
      res
        .status(500)
        .json({ message: "Error updating prediction", error: error.message });
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

// Delete a prediction by ID
exports.deletePrediction = async (req, res) => {
  try {
    const { data: deletedPrediction, error } = await supabase
      .from("predictions")
      .delete()
      .eq("id", req.params.id)
      .select("id")
      .maybeSingle();

    if (error || !deletedPrediction) {
      return res.status(404).json({ message: "Prediction not found" });
    }

    res.status(200).json({ message: "Prediction deleted successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ message: "Error deleting prediction", error: error.message });
  }
};
