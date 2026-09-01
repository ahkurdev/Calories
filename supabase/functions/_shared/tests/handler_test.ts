import { handleAIRequest } from "../ai/handler.ts";
import { AITaskType } from "../ai/types.ts";

Deno.test("handler returns honest manual fallback when providers are not configured", async () => {
  Deno.env.delete("OPENROUTER_API_KEY");
  Deno.env.delete("OPENCODE_API_KEY");
  const response = await handleAIRequest(
    new Request("https://example.test/generate-daily-summary", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        input: {
          stats: {
            date: "2026-09-01",
            targetCalories: 1900,
            consumedCalories: 1800,
            remainingCalories: 100,
            overTargetCalories: 0,
            waterMl: 2000,
            waterTargetMl: 2000,
            activityMinutes: 20,
            estimatedActivityCalories: 80,
          },
        },
      }),
    }),
    AITaskType.dailySummary,
  );
  const body = await response.json();
  if (response.status !== 503 || body.status !== "manual_fallback") {
    throw new Error(
      `Unexpected response: ${response.status} ${JSON.stringify(body)}`,
    );
  }
});

Deno.test("handler rejects task mismatch before provider routing", async () => {
  const response = await handleAIRequest(
    new Request("https://example.test/analyze-food", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        task: "food_recommendation",
        input: { image: { mimeType: "image/jpeg", base64: "aGVsbG8=" } },
      }),
    }),
    AITaskType.foodScan,
  );
  if (response.status !== 400) {
    throw new Error("Task mismatch was not rejected");
  }
});
