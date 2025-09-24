// functions/src/index.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";


const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Extract plain text from the Responses API envelope
function extractTextFromResponses(resBody: any): string | null {
  // 1) Most convenient: output_text
  if (typeof resBody?.output_text === "string" && resBody.output_text.trim().length > 0) {
    return resBody.output_text;
  }
  // 2) Walk output[].content[].text[].value
  const out = resBody?.output;
  if (Array.isArray(out) && out.length > 0) {
    const texts: string[] = [];
    for (const item of out) {
      const contents = item?.content;
      if (Array.isArray(contents)) {
        for (const c of contents) {
          const t = c?.text;
          if (Array.isArray(t)) {
            for (const seg of t) {
              if (typeof seg?.value === "string") texts.push(seg.value);
            }
          } else if (typeof t === "string") {
            texts.push(t);
          }
        }
      }
    }
    if (texts.length) return texts.join("\n");
  }
  // 3) Legacy / fallback
  if (typeof resBody?.content === "string") return resBody.content;
  return null;
}

// Call OpenAI Responses API and return either parsed JSON (if json_object) or string
async function callOpenAI(
  input: any,
  opts: {
    model?: string;
    response_format?: "text" | "json_object";
    temperature?: number;
  } = {}
) {
  const {
    model = "gpt-4o-mini",
    response_format = "json_object",
    temperature = 0.3,
  } = opts;

  const r = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${OPENAI_API_KEY.value()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      input, // array of { role, content }
      // ✅ Use object form for text.format; omit for plain text
      text: response_format === "json_object"
        ? { format: { type: "json_object" } }
        : {},                 // default = plain
      temperature,
      stream: false,
    }),
  });

  const text = await r.text();
  let body: any = null;
  try { body = JSON.parse(text); } catch { /* keep null */ }

  if (!r.ok) {
    // Show exact OpenAI error back to client
    const errMsg = body?.error?.message || text;
    throw new Error(`OpenAI ${r.status}: ${errMsg}`);
  }

  // If caller asked for json_object, model's JSON will be inside the text output — parse it.
  if (response_format === "json_object") {
    const content = extractTextFromResponses(body) ?? text; // fall back to raw
    try {
      return JSON.parse(content);
    } catch {
      // If parsing fails, return envelope so caller can inspect
      return body ?? text;
    }
  }

  // Plain text request
  return extractTextFromResponses(body) ?? text;
}

// ---- Callable: Personalized Panic Plan
export const generatePanicPlan = onCall(
  { region: "europe-west1", secrets: [OPENAI_API_KEY] },
  async (req) => {
    // 🔎 Monitor App Check (don't block)
    if (!req.app) {
      console.warn("generatePanicPlan: NO AppCheck token (monitoring only)");
      // DO NOT throw here while you're testing
    } else {
      console.log("generatePanicPlan: AppCheck ok", req.app);
    }

    // 🔐 Still require Firebase Auth (anon is fine)
    if (!req.auth) throw new HttpsError("unauthenticated", "Missing auth.");

    console.log("generatePanicPlan uid:", req.auth.uid, "data:", req.data);
    try {

      // Extract user's desired duration from intake
      const intake = req.data?.intake ?? {};
      const userDuration = intake.duration || 120; // Default to 2 minutes if not specified
      const durationMinutes = Math.round(userDuration / 60);
      
      const system =
        req.data?.systemPrompt ??
        `
You are a calm, non-clinical coach. Output STRICT JSON {version,title,steps[],personalizedPhrase} only.
Total duration should be approximately ${userDuration} seconds (${durationMinutes} minutes). Allowed steps:
- breathing{pattern:"box|478|coherence", seconds}
- grounding{method:"54321|countback|sensory", seconds}
- muscle_release{area, seconds}
- affirmation{text, seconds}
IMPORTANT: If the user provides a personalizedPhrase in the intake, use that exact phrase. Otherwise, use a gentle, reassuring phrase.
No diagnosis or medical advice.
`.trim();

      const userJson = JSON.stringify(req.data?.intake ?? {});
      const input = [
        { role: "system", content: system },
        { role: "user", content: userJson },
      ];

      const result = await callOpenAI(input, {
        model: "gpt-4o-mini",
        response_format: "json_object",
        temperature: 0.2,
      });

      return result;
    } catch (e: any) {
      throw new HttpsError("internal", "OpenAI call failed", String(e?.message ?? e));
    }
  }
);

// ---- Callable: Daily Check-in (classifier -> micro-exercise)
export const dailyCheckIn = onCall(
  { region: "europe-west1", secrets: [OPENAI_API_KEY] },
  async (req) => {
    if (!req.app) {
      console.warn("dailyCheckIn: NO AppCheck token (monitoring only)");
    } else {
      console.log("dailyCheckIn: AppCheck ok", req.app);
    }

    if (!req.auth) throw new HttpsError("unauthenticated", "Missing auth.");

    console.log("dailyCheckIn uid:", req.auth.uid, "data:", req.data);
    try {

      const checkin = req.data?.checkin;
      if (!checkin || typeof checkin !== "object") {
        throw new HttpsError("invalid-argument", "Expected data.checkin to be an object.");
      }

      // 1) Classify severity
      const classifySystem = `
Classify {mood,tags,note} for mental-distress triage. Output STRICT JSON:
{ "severity": 0|1|2|3, "reason": "string", "suggested_path": "rescue|exercise|journal" }.
3 = imminent risk; 2 = concerning; 1 = mild; 0 = none. No advice here.
`.trim();

      const classification = await callOpenAI(
        [
          { role: "system", content: classifySystem },
          { role: "user", content: JSON.stringify(checkin) },
        ],
        { model: "gpt-4o-mini", response_format: "json_object", temperature: 0.1 }
      );

      // If model returned an envelope instead of parsed JSON (rare), guard it:
      const severity = Number(classification?.severity ?? -1);
      if (severity >= 2) {
        return classification;
      }

      // 2) Generate one micro-exercise
      const exerciseSystem = `
Generate ONE 30–90s micro-exercise as STRICT JSON:
{ "title": string, "duration_sec": number, "steps": [string], "prompt"?: string }.
Match to mood/tags. Keep it practical, non-clinical, no medical advice. JSON only.
`.trim();

      const exercise = await callOpenAI(
        [
          { role: "system", content: exerciseSystem },
          { role: "user", content: JSON.stringify(checkin) },
        ],
        { model: "gpt-4o-mini", response_format: "json_object", temperature: 0.3 }
      );

      return { ...classification, exercise };
    } catch (e: any) {
      throw new HttpsError("internal", "dailyCheckIn failed", String(e?.message ?? e));
    }
  }
);

// ---- HTTP Test Functions (no auth required)
import { onRequest } from "firebase-functions/v2/https";

// sanity: just says ok
export const hello = onRequest({ region: "europe-west1" }, (_req, res) => {
  res.status(200).json({ ok: true, ts: Date.now() });
});

// calls OpenAI with a minimal JSON instruction
export const aiPing = onRequest(
  { region: "europe-west1", secrets: [OPENAI_API_KEY], timeoutSeconds: 60 },
  async (_req, res) => {
    try {
      const input = [
        { role: "system", content: "Reply STRICT JSON: {\"pong\":true}" },
        { role: "user", content: "ping" }
      ];
      const result = await callOpenAI(input, {
        model: "gpt-4o-mini",
        response_format: "json_object",
        temperature: 0
      });
      res.status(200).json(result);
    } catch (e: any) {
      console.error("aiPing error:", e?.message ?? e);
      res.status(500).json({ error: String(e?.message ?? e) });
    }
  }
);

// ---- TEMP: Test Personalized Panic Plan over HTTP
export const testPanicPlan = onRequest(
  { region: "europe-west1", secrets: [OPENAI_API_KEY] },
  async (_req, res) => {
    try {
      const system = `
You are a calm, non-clinical coach. Output STRICT JSON {version,title,steps[],personalizedPhrase} only.
Total duration 60–180 seconds. Allowed steps:
- breathing{pattern:"box|478|coherence", seconds}
- grounding{method:"54321|countback|sensory", seconds}
- muscle_release{area, seconds}
- affirmation{text, seconds}
IMPORTANT: If the user provides a personalizedPhrase in the intake, use that exact phrase. Otherwise, use a gentle, reassuring phrase.
No diagnosis or medical advice.
`.trim();

      const intake = {
        situation: "crowded train",
        body: ["racing heart", "dizzy"],
        preferences: { breathing: "478", grounding: "54321" },
        personalizedPhrase: "I am safe and calm"
      };

      const input = [
        { role: "system", content: system },
        { role: "user", content: JSON.stringify(intake) },
      ];

      const result = await callOpenAI(input, {
        model: "gpt-4o-mini",
        response_format: "json_object",
        temperature: 0.2,
      });

      console.log("testPanicPlan result", result);
      res.status(200).json(result);
    } catch (e: any) {
      console.error("testPanicPlan error:", e?.message ?? e);
      res.status(500).json({ error: String(e?.message ?? e) });
    }
  }
);

// ---- TEMP: Test Daily Check-in over HTTP
export const testCheckIn = onRequest(
  { region: "europe-west1", secrets: [OPENAI_API_KEY] },
  async (_req, res) => {
    try {
      const classifySystem = `
Classify {mood,tags,note} for mental-distress triage. Output STRICT JSON:
{ "severity": 0|1|2|3, "reason": "string", "suggested_path": "rescue|exercise|journal" }.
3 = imminent risk; 2 = concerning; 1 = mild; 0 = none. No advice here.
`.trim();

      const checkin = { mood: 4, tags: ["tired","overwhelmed"], note: "slept 4h" };

      const classification = await callOpenAI(
        [
          { role: "system", content: classifySystem },
          { role: "user", content: JSON.stringify(checkin) },
        ],
        { model: "gpt-4o-mini", response_format: "json_object", temperature: 0.1 }
      );

      if ((Number(classification?.severity) || 0) >= 2) {
        console.log("testCheckIn classification", classification);
        res.status(200).json(classification);
        return;
      }

      const exerciseSystem = `
Generate ONE 30–90s micro-exercise as STRICT JSON:
{ "title": string, "duration_sec": number, "steps": [string], "prompt"?: string }.
Match to mood/tags. Keep it practical, non-clinical, no medical advice. JSON only.
`.trim();

      const exercise = await callOpenAI(
        [
          { role: "system", content: exerciseSystem },
          { role: "user", content: JSON.stringify(checkin) },
        ],
        { model: "gpt-4o-mini", response_format: "json_object", temperature: 0.3 }
      );

      const out = { ...classification, exercise };
      console.log("testCheckIn result", out);
      res.status(200).json(out);
    } catch (e: any) {
      console.error("testCheckIn error:", e?.message ?? e);
      res.status(500).json({ error: String(e?.message ?? e) });
    }
  }
);

// ---- Emergency Companion removed - replaced with AI-enhanced Panic Plan and Daily Coach

// ---- Safety and Moderation Functions

async function checkRateLimit(userId: string): Promise<{allowed: boolean, message: string, usageCount: number}> {
  const today = new Date().toISOString().split('T')[0].replace(/-/g, '');
  const docId = `${userId}_${today}`;
  
  // This would connect to Firestore in a real implementation
  // For now, return a simple check
  const usageCount = 0; // Would be fetched from Firestore
  const maxDailyUsage = 30; // Premium tier limit (reasonable for paying customers)
  
  if (usageCount >= maxDailyUsage) {
    return {
      allowed: false,
      message: "You've had a lot of conversations with your Companion today. Sometimes it helps to take a break and use your Emergency Plan or a breathing exercise. I'll be ready when you check in again tomorrow.",
      usageCount
    };
  }
  
  return { allowed: true, message: "", usageCount };
}

async function moderateInput(text: string): Promise<{isCrisis: boolean, isDisallowed: boolean}> {
  const lowerText = text.toLowerCase();
  
  // Crisis keywords
  const crisisKeywords = [
    'suicide', 'kill myself', 'end my life', 'not worth living',
    'hurt myself', 'self harm', 'cut myself', 'overdose',
    'jump off', 'hang myself', 'shoot myself', 'poison myself'
  ];
  
  // Disallowed content keywords
  const disallowedKeywords = [
    'medication', 'drugs', 'pills', 'dosage', 'prescription',
    'therapy', 'therapist', 'psychiatrist', 'diagnosis',
    'profanity', 'sexual', 'violence', 'weapons'
  ];
  
  const isCrisis = crisisKeywords.some(keyword => lowerText.includes(keyword));
  const isDisallowed = disallowedKeywords.some(keyword => lowerText.includes(keyword));
  
  return { isCrisis, isDisallowed };
}

async function moderateOutput(text: string): Promise<{flagged: boolean}> {
  // Simple output moderation - in production, use OpenAI's moderation API
  const lowerText = text.toLowerCase();
  const flaggedKeywords = [
    'medication', 'drugs', 'pills', 'dosage', 'prescription',
    'therapy', 'therapist', 'psychiatrist', 'diagnosis'
  ];
  
  const flagged = flaggedKeywords.some(keyword => lowerText.includes(keyword));
  return { flagged };
}

function getEmergencyCompanionSystemPrompt(): string {
  return `You are a supportive, empathetic companion helping someone through a difficult moment. You provide practical, calming guidance.

GUIDELINES:
• Be warm, understanding, and conversational
• Provide practical calming techniques (breathing, grounding, mindfulness)
• Keep responses brief but helpful (2-4 sentences)
• Vary your responses - never repeat the same message or technique
• For normal emotional distress, offer specific calming techniques
• Only mention crisis resources if user explicitly mentions self-harm or suicide
• Be creative and adapt to what the user is saying

RESPONSE STYLE:
• Be conversational and supportive
• Offer specific, actionable advice
• Acknowledge their feelings
• Provide practical next steps
• Keep it under 100 words
• Always respond differently - avoid repetitive patterns

CALMING TECHNIQUES TO ROTATE:
- Box breathing (4-4-4-4)
- Progressive muscle relaxation
- Mindful observation
- Self-compassion statements
- Sensory grounding (5-4-3-2-1)
- Heart-focused breathing
- Gentle movement suggestions
- Positive affirmations

If this is the first message, include: "I'm not a therapist, but I'm here to help you through this moment."`;
}

function getCrisisResponse(locale: string): string {
  // Extract country code from locale (e.g., "en-US" -> "US")
  const countryCode = locale.split('-')[1] || 'US';
  
  // Get appropriate emergency number based on country
  const emergencyNumber = getEmergencyNumber(countryCode);
  const crisisHotline = getCrisisHotline(countryCode);
  
  if (emergencyNumber === crisisHotline) {
    return `I'm very concerned about what you're sharing. Your safety is the most important thing right now.

If you're in immediate danger, call ${emergencyNumber} for emergency services.

For crisis support, visit findahelpline.com to find resources in your country.

You're not alone, and there are people who want to help you. Your life has value.`;
  } else {
    return `I'm very concerned about what you're sharing. Your safety is the most important thing right now.

If you're in immediate danger, call ${emergencyNumber} for emergency services.

For crisis support, call ${crisisHotline} or visit findahelpline.com for more resources.

You're not alone, and there are people who want to help you. Your life has value.`;
  }
}

function getEmergencyNumber(countryCode: string): string {
  const emergencyNumbers: { [key: string]: string } = {
    'US': '911',
    'CA': '911',
    'GB': '112',
    'DE': '112',
    'FR': '112',
    'ES': '112',
    'IT': '112',
    'NL': '112',
    'BE': '112',
    'AU': '000'
  };
  
  return emergencyNumbers[countryCode] || '112';
}

function getCrisisHotline(countryCode: string): string {
  const crisisHotlines: { [key: string]: string } = {
    'US': '988',
    'CA': '988',
    'GB': '116 123',
    'DE': '0800 111 0 111',
    'FR': '3114',
    'ES': '717 003 717',
    'IT': '800 86 00 22',
    'NL': '113',
    'BE': '1813',
    'AU': '13 11 14'
  };
  
  return crisisHotlines[countryCode] || '112';
}

async function logUsage(userId: string, type: string, content: string): Promise<void> {
  // In production, this would log to Firestore
  // eslint-disable-next-line no-console
  console.log(`Usage log: ${userId} - ${type} - ${content.substring(0, 100)}...`);
}