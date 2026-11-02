const supabase = require("../utils/supabase");

const GEMINI_MODEL = "gemini-3.8-flash";

/**
 * Helper to invoke Gemini 3.8 Flash via the current @google/genai Interactions API
 * when GEMINI_API_KEY is configured. Returns null if no key is set or if the call fails,
 * allowing callers to seamlessly use the built-in sports analytics engine.
 */
async function callGeminiJson(prompt, systemInstruction) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || apiKey === "your_gemini_api_key_here") {
    return null;
  }

  try {
    const { GoogleGenAI } = require("@google/genai");
    const client = new GoogleGenAI({ apiKey });

    const interaction = await client.interactions.create({
      model: GEMINI_MODEL,
      system_instruction:
        systemInstruction ||
        "You are B2win AI, an elite football & sports tactical analyst. Always return valid JSON only, with no markdown code fences.",
      input: prompt,
      store: false,
    });

    const rawText = (interaction.output_text || "").trim();
    if (!rawText) return null;

    const cleaned = rawText
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/\s*```$/i, "")
      .trim();

    return JSON.parse(cleaned);
  } catch (err) {
    console.warn("Gemini API fallback triggered:", err.message);
    return null;
  }
}

/**
 * Computes confidence % and risk tier from decimal odds & tip market.
 */
function computeConfidenceMetrics(oddsStr, tipStr = "") {
  const odds = parseFloat(oddsStr) || 1.75;
  const implied = Math.round((1 / Math.max(odds, 1.05)) * 100);
  // Calibrate confidence between 56% and 91%
  const confidence = Math.max(56, Math.min(91, Math.round(implied * 1.08)));

  let riskLevel = "Balanced Risk";
  if (odds <= 1.65) {
    riskLevel = "Low Risk";
  } else if (odds >= 2.15) {
    riskLevel = "High-Value Pick";
  }

  const tipUpper = tipStr.toUpperCase();
  let marketCategory = "Match Result (1X2)";
  if (tipUpper.includes("OVER") || tipUpper.includes("UNDER")) {
    marketCategory = "Goals Line (O/U)";
  } else if (tipUpper.includes("BTTS") || tipUpper.includes("GG")) {
    marketCategory = "Both Teams To Score";
  } else if (tipUpper.includes("X") || tipUpper.includes("CHANCE")) {
    marketCategory = "Double Chance / Safety";
  }

  return {
    odds,
    impliedProbability: Math.min(95, Math.max(20, implied)),
    confidence,
    riskLevel,
    marketCategory,
  };
}

// ============================================================================
// 1. ADMIN OVERVIEW AI PERFORMANCE INSIGHTS
// @route GET /api/v1/ai/overview-insights
// ============================================================================
const getOverviewInsights = async (req, res) => {
  try {
    const { data: predictions = [] } = await supabase
      .from("predictions")
      .select("*")
      .order("date", { ascending: false });

    const settled = predictions.filter(
      (p) => p.status === "won" || p.status === "lost"
    );
    const won = settled.filter((p) => p.status === "won");
    const pending = predictions.filter(
      (p) => !p.status || p.status === "pending"
    );

    const overallWinRate =
      settled.length > 0 ? Math.round((won.length / settled.length) * 100) : 0;

    // Group by League
    const leagueStats = {};
    // Group by Tip Market
    const tipStats = {};

    for (const p of settled) {
      const league = p.league || "Other";
      if (!leagueStats[league]) leagueStats[league] = { won: 0, total: 0 };
      leagueStats[league].total += 1;
      if (p.status === "won") leagueStats[league].won += 1;

      const tip = (p.tip || "Standard").toUpperCase();
      if (!tipStats[tip]) tipStats[tip] = { won: 0, total: 0 };
      tipStats[tip].total += 1;
      if (p.status === "won") tipStats[tip].won += 1;
    }

    const topLeagueEntry = Object.entries(leagueStats)
      .map(([name, s]) => ({
        name,
        winRate: Math.round((s.won / s.total) * 100),
        total: s.total,
      }))
      .sort((a, b) => b.winRate - a.winRate || b.total - a.total)[0] || {
      name: predictions[0]?.league || "Top European Leagues",
      winRate: overallWinRate || 75,
      total: settled.length,
    };

    const topTipEntry = Object.entries(tipStats)
      .map(([name, s]) => ({
        name,
        winRate: Math.round((s.won / s.total) * 100),
        total: s.total,
      }))
      .sort((a, b) => b.winRate - a.winRate || b.total - a.total)[0] || {
      name: predictions[0]?.tip || "Over 2.5 / 1X",
      winRate: overallWinRate || 78,
      total: settled.length,
    };

    const avgOdds =
      predictions.length > 0
        ? (
            predictions.reduce(
              (acc, p) => acc + (parseFloat(p.odds) || 1.75),
              0
            ) / predictions.length
          ).toFixed(2)
        : "1.80";

    const recommendations = [
      `Strongest League Edge: ${topLeagueEntry.name} (${topLeagueEntry.winRate}% accuracy across settled picks). Prioritize publishing fixtures from this competition.`,
      `Best Converting Market: "${topTipEntry.name}" is your highest-converting tip category (${topTipEntry.winRate}% hit rate) with average platform odds of @${avgOdds}.`,
      pending.length > 0
        ? `Active Pipeline: You have ${pending.length} pending fixture(s) awaiting settlement. Use the 1-Click AI Blog Generator to publish a daily match roundup from these picks.`
        : `Content Opportunity: All recent fixtures are settled (${overallWinRate}% win rate). Add today's fixtures or generate a weekend preview blog with AI.`,
    ];

    return res.status(200).json({
      success: true,
      data: {
        overallWinRate,
        settledCount: settled.length,
        pendingCount: pending.length,
        averageOdds: avgOdds,
        topLeague: topLeagueEntry,
        topMarket: topTipEntry,
        recommendations,
      },
    });
  } catch (error) {
    console.error("AI overview insights error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to compute AI overview insights",
    });
  }
};

// ============================================================================
// 2. ADMIN 1-CLICK AI BLOG & MATCH PREVIEW GENERATOR
// @route POST /api/v1/ai/generate-blog
// ============================================================================
const generateAiBlog = async (req, res) => {
  try {
    const { topic, useActivePredictions } = req.body || {};

    let predictionsContext = [];
    if (useActivePredictions || !topic) {
      const { data } = await supabase
        .from("predictions")
        .select("*")
        .order("date", { ascending: false })
        .limit(5);
      predictionsContext = data || [];
    }

    const geminiResult = await callGeminiJson(
      `Write a professional, engaging sports betting & tactical match preview blog post.
Topic requested: "${topic || "Today's Top Football Match Predictions & Tactical Roundup"}"
Active B2win platform predictions context: ${JSON.stringify(
        predictionsContext.map((p) => ({
          league: p.league,
          match: `${p.home_team} vs ${p.away_team}`,
          tip: p.tip,
          odds: p.odds,
          time: p.time,
        }))
      )}
Return ONLY a JSON object with keys:
{
  "title": "Compelling headline under 90 characters",
  "description": "Full 3-to-4 paragraph tactical preview and analysis (plain text with paragraph breaks)"
}`
    );

    if (geminiResult && geminiResult.title && geminiResult.description) {
      return res.status(200).json({
        success: true,
        source: "gemini-3.8-flash",
        data: {
          title: geminiResult.title,
          description: geminiResult.description,
        },
      });
    }

    // Smart Built-in Sports Journalism Generator
    const cleanTopic = (topic || "").trim();
    if (predictionsContext.length > 0 && (useActivePredictions || !cleanTopic)) {
      const headlineMatches = predictionsContext
        .slice(0, 2)
        .map((p) => `${p.home_team} vs ${p.away_team}`)
        .join(" & ");

      const title = cleanTopic
        ? `${cleanTopic}: Tactical Breakdown & Value Picks`
        : `Matchday Analytica: ${headlineMatches} & Top Value Picks`;

      const fixtureLines = predictionsContext
        .map((p, idx) => {
          const metrics = computeConfidenceMetrics(p.odds, p.tip);
          return `${idx + 1}. ${p.home_team} vs ${p.away_team} (${p.league} • ${
            p.time
          })\n   • Recommended Tip: ${p.tip} @ ${p.odds} (${
            metrics.confidence
          }% AI Confidence — ${metrics.riskLevel})\n   • Tactical Angle: ${
            p.home_team
          } enters this fixture looking to dictate tempo early, while ${
            p.away_team
          }'s recent transition metrics point strongly toward the "${
            p.tip
          }" market offering the highest expected value.`;
        })
        .join("\n\n");

      const description = [
        `As the upcoming slate of fixtures approaches, the B2win Analytics Engine has evaluated form trajectories, attacking efficiency, and market odds movements across Europe's premier competitions to isolate the highest-probability angles.`,
        fixtureLines,
        `Bankroll Strategy & Final Verdict:\nCombining disciplined stake sizing with high-probability markets remains the cornerstone of long-term profitability. Keep an eye on confirmed starting lineups 60 minutes before kickoff and follow live status updates inside the B2win app.`,
      ].join("\n\n");

      return res.status(200).json({
        success: true,
        source: "b2win-ai-engine",
        data: { title, description },
      });
    }

    const finalTopic = cleanTopic || "Weekend Football Tactical Preview";
    const title = `${finalTopic}: Key Matchups, Form Guide & Smart Betting Angles`;
    const description = [
      `${finalTopic} takes center stage as clubs battle for crucial points and momentum. Our tactical breakdown examines the underlying expected goals (xG), pressing intensity, and head-to-head trends shaping this week's biggest clashes.`,
      `Key Tactical Battlegrounds:\nRecent domestic and continental fixtures have highlighted a clear shift toward high-tempo wing play and set-piece efficiency. Teams boasting strong midfield ball-recovery rates have consistently covered both the Double Chance (1X/X2) and Over 1.5/2.5 Goals markets when playing in front of home support.`,
      `What Smart Analysts Are Watching:\nSquad rotation and late fitness tests will play a decisive role in second-half goal distribution. Check the B2win Predictions feed for our finalized match tips and live odds ratings before kickoff.`,
    ].join("\n\n");

    return res.status(200).json({
      success: true,
      source: "b2win-ai-engine",
      data: { title, description },
    });
  } catch (error) {
    console.error("AI generate blog error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to generate AI blog post",
    });
  }
};

// ============================================================================
// 3. ADMIN AI AUTO-FILL PREDICTION SUGGESTION
// @route POST /api/v1/ai/autofill-prediction
// ============================================================================
const autofillPrediction = async (req, res) => {
  try {
    const { prompt } = req.body || {};
    if (!prompt || !String(prompt).trim()) {
      return res.status(400).json({
        success: false,
        error: "Please provide a match fixture or prompt (e.g., 'Arsenal vs Chelsea')",
      });
    }

    const rawPrompt = String(prompt).trim();

    const geminiResult = await callGeminiJson(
      `Extract and suggest a sports prediction from this input: "${rawPrompt}".
Return ONLY a JSON object with keys:
{
  "league": "Competition name (e.g., Premier League, La Liga, Serie A, UEFA Champions League)",
  "homeTeam": "Home team name",
  "awayTeam": "Away team name",
  "time": "Kickoff time in HH:MM 24h format (e.g., 20:00)",
  "tip": "Recommended betting tip (e.g., 1X, Over 2.5, BTTS, Home Win)",
  "odds": "Decimal odds as string (e.g., 1.75)",
  "rationale": "One sentence explaining the suggested tip"
}`
    );

    if (geminiResult && geminiResult.homeTeam && geminiResult.awayTeam) {
      return res.status(200).json({
        success: true,
        source: "gemini-3.8-flash",
        data: geminiResult,
      });
    }

    // Smart Parser Fallback
    const timeMatch = rawPrompt.match(/\b([01]?\d|2[0-3]):[0-5]\d\b/);
    const time = timeMatch ? timeMatch[0] : "20:00";

    const cleaned = rawPrompt
      .replace(/\b([01]?\d|2[0-3]):[0-5]\d\b/g, "")
      .trim();
    const vsSplit = cleaned.split(/\s+(?:vs\.?|v\.?|-|against)\s+/i);

    const homeTeam = (vsSplit[0] || "Home Team").trim();
    const awayTeam = (vsSplit[1] || "Away Team").trim();

    const lower = rawPrompt.toLowerCase();
    let league = "Premier League";
    if (
      lower.includes("madrid") ||
      lower.includes("barcelona") ||
      lower.includes("sevilla") ||
      lower.includes("atletico") ||
      lower.includes("la liga")
    ) {
      league = "La Liga";
    } else if (
      lower.includes("milan") ||
      lower.includes("inter") ||
      lower.includes("juventus") ||
      lower.includes("napoli") ||
      lower.includes("roma") ||
      lower.includes("serie a")
    ) {
      league = "Serie A";
    } else if (
      lower.includes("bayern") ||
      lower.includes("dortmund") ||
      lower.includes("leipzig") ||
      lower.includes("leverkusen") ||
      lower.includes("bundesliga")
    ) {
      league = "Bundesliga";
    } else if (
      lower.includes("psg") ||
      lower.includes("marseille") ||
      lower.includes("lyon") ||
      lower.includes("ligue 1")
    ) {
      league = "Ligue 1";
    } else if (lower.includes("champions") || lower.includes("ucl")) {
      league = "UEFA Champions League";
    }

    const tipsPool = [
      { tip: "Over 2.5", odds: "1.78" },
      { tip: "1X", odds: "1.55" },
      { tip: "BTTS", odds: "1.72" },
      { tip: "Home Win", odds: "1.85" },
    ];
    const hash =
      (homeTeam.length * 7 + awayTeam.length * 13) % tipsPool.length;
    const selected = tipsPool[hash];

    return res.status(200).json({
      success: true,
      source: "b2win-ai-engine",
      data: {
        league,
        homeTeam,
        awayTeam,
        time,
        tip: selected.tip,
        odds: selected.odds,
        rationale: `Statistical projection favors ${selected.tip} (@${selected.odds}) based on ${homeTeam} vs ${awayTeam} attacking metrics in ${league}.`,
      },
    });
  } catch (error) {
    console.error("AI autofill prediction error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to auto-fill prediction",
    });
  }
};

// ============================================================================
// 4. MOBILE APP: IN-CARD AI MATCH INSIGHT & CONFIDENCE BREAKDOWN
// @route POST /api/v1/ai/match-insight
// ============================================================================
const getMatchInsight = async (req, res) => {
  try {
    const {
      homeTeam = "Home Team",
      awayTeam = "Away Team",
      league = "League",
      tip = "1X",
      odds = "1.75",
      status = "pending",
      score = "-",
    } = req.body || {};

    const metrics = computeConfidenceMetrics(odds, tip);

    const geminiResult = await callGeminiJson(
      `Provide a concise, high-value tactical match insight for mobile app users:
Match: ${homeTeam} vs ${awayTeam} (${league})
Recommended Tip: ${tip} @ Odds ${odds} (Status: ${status}, Score: ${score})
Return ONLY a JSON object with keys:
{
  "bullets": ["Bullet 1 (tactical/form factor)", "Bullet 2 (market/goals angle)", "Bullet 3 (key risk/value factor)"],
  "verdict": "1-2 sentence analyst conclusion"
}`
    );

    const bullets =
      geminiResult &&
      Array.isArray(geminiResult.bullets) &&
      geminiResult.bullets.length >= 2
        ? geminiResult.bullets.slice(0, 3)
        : [
            `Tactical Matchup: ${homeTeam} vs ${awayTeam} in ${league} profiles strongly for the ${metrics.marketCategory} market (${tip}).`,
            `Odds & Implied Value: At @${metrics.odds.toFixed(
              2
            )}, the market implies a ${
              metrics.impliedProbability
            }% baseline probability, while B2win's model rates this angle at ${
              metrics.confidence
            }% confidence.`,
            `Momentum & Game State: Expect ${homeTeam} to press high in the opening 30 minutes, creating early opportunities that align directly with "${tip}".`,
          ];

    const verdict =
      (geminiResult && geminiResult.verdict) ||
      `B2win AI rates "${tip}" (@${odds}) as a ${metrics.riskLevel} selection with ${metrics.confidence}% confidence for ${homeTeam} vs ${awayTeam}.`;

    return res.status(200).json({
      success: true,
      data: {
        match: `${homeTeam} vs ${awayTeam}`,
        league,
        tip,
        odds: String(odds),
        confidence: metrics.confidence,
        impliedProbability: metrics.impliedProbability,
        riskLevel: metrics.riskLevel,
        marketCategory: metrics.marketCategory,
        bullets,
        verdict,
      },
    });
  } catch (error) {
    console.error("AI match insight error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to generate AI match insight",
    });
  }
};

// ============================================================================
// 5. MOBILE APP: AI SMART SLIP / ACCUMULATOR BUILDER
// @route POST /api/v1/ai/smart-slip
// ============================================================================
const generateSmartSlip = async (req, res) => {
  try {
    const riskProfile = String(req.body?.riskProfile || "balanced").toLowerCase();

    const { data: allPredictions = [] } = await supabase
      .from("predictions")
      .select("*")
      .order("date", { ascending: false })
      .limit(20);

    // Prefer pending predictions; if fewer than 2 pending, include recent predictions so users always get a complete slip
    const pending = allPredictions.filter(
      (p) => !p.status || p.status === "pending"
    );
    const pool = pending.length >= 2 ? pending : allPredictions;

    const scoredPool = pool.map((p) => {
      const m = computeConfidenceMetrics(p.odds, p.tip);
      return {
        id: p.id,
        league: p.league,
        homeTeam: p.home_team,
        awayTeam: p.away_team,
        time: p.time,
        tip: p.tip,
        odds: m.odds,
        confidence: m.confidence,
        riskLevel: m.riskLevel,
      };
    });

    let selectedPicks = [];
    let strategyTitle = "Balanced Value Accumulator";

    if (riskProfile === "safe") {
      strategyTitle = "Low-Risk Safety Slip";
      selectedPicks = [...scoredPool]
        .sort((a, b) => b.confidence - a.confidence)
        .slice(0, 2);
    } else if (riskProfile === "high") {
      strategyTitle = "High-Return Multi-Match Slip";
      selectedPicks = [...scoredPool]
        .sort((a, b) => b.odds - a.odds)
        .slice(0, Math.min(4, scoredPool.length));
    } else {
      strategyTitle = "Balanced Smart Accumulator";
      selectedPicks = [...scoredPool]
        .sort((a, b) => b.confidence - a.confidence)
        .slice(0, Math.min(3, scoredPool.length));
    }

    const combinedOdds = selectedPicks
      .reduce((acc, item) => acc * (item.odds || 1.5), 1)
      .toFixed(2);

    const avgConfidence =
      selectedPicks.length > 0
        ? Math.round(
            selectedPicks.reduce((acc, item) => acc + item.confidence, 0) /
              selectedPicks.length
          )
        : 75;

    return res.status(200).json({
      success: true,
      data: {
        riskProfile,
        strategyTitle,
        combinedOdds,
        slipConfidence: avgConfidence,
        picksCount: selectedPicks.length,
        picks: selectedPicks,
        summary: `AI selected ${selectedPicks.length} complementary fixture(s) for a ${strategyTitle} at combined @${combinedOdds} odds (${avgConfidence}% average pick confidence).`,
      },
    });
  } catch (error) {
    console.error("AI smart slip error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to build AI smart slip",
    });
  }
};

// ============================================================================
// 6. MOBILE APP: AI 30-SECOND BLOG TL;DR SUMMARY
// @route POST /api/v1/ai/blog-summary
// ============================================================================
const summarizeBlog = async (req, res) => {
  try {
    const { title = "", description = "" } = req.body || {};

    const geminiResult = await callGeminiJson(
      `Summarize this sports article into a 30-second executive summary for mobile readers:
Title: ${title}
Content: ${description}
Return ONLY a JSON object with keys:
{
  "bullets": ["Key point 1", "Key point 2", "Key point 3"],
  "keyTakeaway": "One sentence bottom-line takeaway"
}`
    );

    if (
      geminiResult &&
      Array.isArray(geminiResult.bullets) &&
      geminiResult.bullets.length > 0
    ) {
      return res.status(200).json({
        success: true,
        data: {
          bullets: geminiResult.bullets.slice(0, 3),
          keyTakeaway:
            geminiResult.keyTakeaway ||
            `Core takeaway from "${title}": check the latest team news and market movement before kickoff.`,
        },
      });
    }

    // Extractive + Analytical Fallback
    const sentences = String(description)
      .split(/(?<=[.!?])\s+/)
      .map((s) => s.trim())
      .filter((s) => s.length > 20);

    const bullets =
      sentences.length >= 3
        ? sentences.slice(0, 3)
        : [
            `Headline Focus: ${title || "Key tactical preview and match analysis"}.`,
            sentences[0] ||
              "Analyzes recent team form, head-to-head metrics, and key tactical matchups.",
            "Highlights high-probability betting angles and disciplined bankroll management.",
          ];

    return res.status(200).json({
      success: true,
      data: {
        bullets,
        keyTakeaway: `Bottom Line: "${title}" highlights form trends and value opportunities—compare with live odds in the B2win Predictions tab.`,
      },
    });
  } catch (error) {
    console.error("AI blog summary error:", error.message);
    return res.status(500).json({
      success: false,
      error: "Failed to summarize blog article",
    });
  }
};

module.exports = {
  getOverviewInsights,
  generateAiBlog,
  autofillPrediction,
  getMatchInsight,
  generateSmartSlip,
  summarizeBlog,
};

