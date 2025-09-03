import { onCall } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");

// Helper: call OpenAI Responses API
async function callOpenAI(input: any, {
  model = "gpt-4o-mini",
  response_format = "json_object",
  temperature = 0.3
}: { model?: string; response_format?: "text"|"json_object"; temperature?: number } = {}) {

  const r = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY.value()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      input,
      response_format,
      temperature,
      stream: false // callable can't stream
    }),
  });

  if (!r.ok) {
    const text = await r.text();
    throw new Error(`OpenAI error (${r.status}): ${text}`);
  }
  // If response_format is "json_object", parse JSON string
  const text = await r.text();
  return text.startsWith("{") || text.startsWith("[") ? JSON.parse(text) : text;
}

/**
 * Callable: Generate or update a Personalized Panic Plan (JSON)
 * data: { intake: {...}, systemPrompt?: string }
 */
export const generatePanicPlan = onCall(
  { region: "europe-west1", secrets: [OPENAI_API_KEY] },
  async (req) => {
    // Auth is optional but recommended:
    if (!req.auth) { throw new Error("UNAUTHENTICATED"); }

    const system = req.data?.systemPrompt ?? `
You are a calm, non-clinical coach. Output STRICT JSON {version,title,steps[]} only.
Total duration 60–180 seconds. Allowed steps:
- breathing{pattern:"box|478|coherence", seconds}
- grounding{method:"54321|countback|sensory", seconds}
- muscle_release{area, seconds}
- affirmation{text, seconds}
No diagnosis or medical advice.
`;
    const userJson = JSON.stringify(req.data?.intake ?? {});

    const input = [
      { role: "system", content: system },
      { role: "user", content: userJson }
    ];

    const result = await callOpenAI(input, {
      model: "gpt-4o-mini",
      response_format: "json_object",
      temperature: 0.2
    });
    return result; // <- returns JSON to client
  }
);

/**
 * Callable: Daily Check-in (Classifier → Micro-exercise)
 * data: { checkin: { mood:number, tags:string[], note?:string } }
 * Returns: { severity, reason, suggested_path, exercise? }
 */
export const dailyCheckIn = onCall(
  { region: "europe-west1", secrets: [OPENAI_API_KEY] },
  async (req) => {
    if (!req.auth) { throw new Error("UNAUTHENTICATED"); }

    const { checkin } = req.data ?? {};
    if (!checkin) { throw new Error("INVALID_ARGUMENT"); }

    // 1) Classify severity
    const classSystem = `
Classify {mood,tags,note} for mental-distress triage. Output JSON:
{ "severity": 0|1|2|3, "reason": "string", "suggested_path": "rescue|exercise|journal" }.
3 = imminent risk; 2 = concerning; 1 = mild; 0 = none. No advice here.
`;
    const classifyInput = [
      { role: "system", content: classSystem },
      { role: "user", content: JSON.stringify(checkin) }
    ];
    const classification = await callOpenAI(classifyInput, {
      model: "gpt-4o-mini",
      response_format: "json_object",
      temperature: 0.1
    });

    if (classification.severity >= 2) {
      return { ...classification }; // client shows resources / Panic Plan shortcut
    }

    // 2) Generate micro-exercise
    const exSystem = `
Generate ONE 30–90s micro-exercise as JSON:
{ "title": string, "duration_sec": number, "steps": [string], "prompt"?: string }.
Match to the user's mood/tags. Keep it practical, non-clinical, no medical advice. JSON only.
`;
    const exerciseInput = [
      { role: "system", content: exSystem },
      { role: "user", content: JSON.stringify(checkin) }
    ];
    const exercise = await callOpenAI(exerciseInput, {
      model: "gpt-4o-mini",
      response_format: "json_object",
      temperature: 0.3
    });

    return { ...classification, exercise };
  }
);