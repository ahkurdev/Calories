import { AIResponseNormalizer } from "../ai/response_normalizer.ts";
import { AITaskType } from "../ai/types.ts";

function assertThrows(fn: () => unknown, expectedCode: string) {
  try {
    fn();
    throw new Error("Expected function to throw");
  } catch (error) {
    if (!(error instanceof Error) || !error.message.includes(expectedCode)) {
      throw error;
    }
  }
}

Deno.test("normalizer removes a single JSON markdown fence", () => {
  const result = AIResponseNormalizer.normalize(
    AITaskType.foodScan,
    '```json\n{"status":"not_food","foods":[],"total_estimated_calories":0,"confidence":0,"notes":"Tidak ditemukan makanan."}\n```',
  );
  if (result.status !== "not_food") throw new Error("Unexpected status");
});

Deno.test("normalizer rejects malformed, executable, and out-of-range output", () => {
  for (
    const payload of [
      "not json",
      '{"status":"success","foods":[],"notes":"<script>alert(1)</script>"}',
      '{"status":"success","foods":[{"name":"Nasi","estimated_grams":100,"estimated_calories":200,"confidence":2}],"total_estimated_calories":200,"notes":"x"}',
    ]
  ) {
    assertThrows(
      () => AIResponseNormalizer.normalize(AITaskType.foodScan, payload),
      "invalid_response",
    );
  }
});

Deno.test("normalizer enforces the exact text contract for each task", () => {
  const result = AIResponseNormalizer.normalize(
    AITaskType.dailySummary,
    '{"status":"success","summary":"Catatan hari ini cukup dekat dengan target."}',
  );
  if (result.status !== "success") throw new Error("Unexpected status");

  for (
    const payload of [
      '{"status":"success","recommendation":"wrong key"}',
      '{"status":"success","summary":"valid","source_code":"no"}',
    ]
  ) {
    assertThrows(
      () => AIResponseNormalizer.normalize(AITaskType.dailySummary, payload),
      "invalid_response",
    );
  }
});

Deno.test("normalizer accepts structured Indonesian food guidance", () => {
  const result = AIResponseNormalizer.normalize(
    AITaskType.foodRecommendation,
    JSON.stringify({
      status: "success",
      recommendation:
        "Untuk makan malam, pilih porsi yang cukup dan tetap perhatikan rasa lapar.",
      foods_to_choose: [{
        name: "Ayam bakar",
        reason: "Protein yang praktis dan mudah dipadukan dengan sayur.",
      }],
      foods_to_limit: [{
        name: "Gorengan",
        reason: "Batasi porsinya karena kalorinya mudah bertambah.",
      }],
      disclaimer:
        "Rekomendasi ini bersifat umum dan bukan pengganti nasihat medis.",
    }),
  );

  if (!Array.isArray(result.foods_to_choose)) {
    throw new Error("Expected foods_to_choose");
  }
});

Deno.test("normalizer rejects English-only AI answers", () => {
  assertThrows(
    () =>
      AIResponseNormalizer.normalize(
        AITaskType.dailySummary,
        '{"status":"success","summary":"Your calorie intake is close to the daily target."}',
      ),
    "invalid_response",
  );
});
