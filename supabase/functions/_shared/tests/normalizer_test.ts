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
