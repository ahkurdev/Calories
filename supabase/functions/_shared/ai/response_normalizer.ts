import { AIError } from "./errors.ts";
import { AITaskType } from "./types.ts";

const maxResponseBytes = 32_768;
const executableContent = [
  /<script\b/i,
  /javascript:/i,
  /(?:^|\s)(?:import|export)\s+.+from\s+["']/im,
  /(?:^|\s)(?:function|class)\s+[A-Za-z_$][\w$]*\s*[({]/m,
  /(?:^|\s)(?:SELECT|INSERT|UPDATE|DELETE|DROP|ALTER)\s+.+\s+(?:FROM|INTO|TABLE|SET)/im,
  /```(?:dart|python|javascript|typescript|java|sql|bash|sh)/i,
];

export class AIResponseNormalizer {
  static normalize(task: AITaskType, raw: string): Record<string, unknown> {
    if (new TextEncoder().encode(raw).byteLength > maxResponseBytes) {
      throw new AIError("invalid_response", "Provider response is too large.");
    }
    const clean = stripFence(raw.trim());
    let parsed: unknown;
    try {
      parsed = JSON.parse(clean);
    } catch {
      throw new AIError(
        "invalid_response",
        "Provider returned malformed JSON.",
      );
    }
    if (!isPlainObject(parsed)) {
      throw new AIError(
        "invalid_response",
        "Provider response must be an object.",
      );
    }
    rejectExecutable(parsed);
    if (
      task === AITaskType.foodScan || task === AITaskType.foodCalorieEstimation
    ) {
      validateFoodResult(parsed);
    } else {
      validateTextResult(task, parsed);
    }
    return parsed;
  }
}

function stripFence(value: string): string {
  const match = value.match(/^```(?:json)?\s*([\s\S]*?)\s*```$/i);
  return match?.[1]?.trim() ?? value;
}

function validateFoodResult(value: Record<string, unknown>) {
  exactKeys(value, [
    "status",
    "foods",
    "total_estimated_calories",
    "confidence",
    "notes",
  ]);
  const allowedStatus = ["success", "not_food", "out_of_scope"];
  if (!allowedStatus.includes(String(value.status))) invalid("Invalid status.");
  if (!Array.isArray(value.foods) || value.foods.length > 30) {
    invalid("Invalid foods.");
  }
  for (const rawFood of value.foods) {
    if (!isPlainObject(rawFood)) invalid("Invalid food item.");
    exactKeys(rawFood, [
      "name",
      "estimated_grams",
      "estimated_calories",
      "confidence",
      "unit",
      "cooking_method",
    ]);
    const name = rawFood.name;
    const grams = rawFood.estimated_grams;
    const calories = rawFood.estimated_calories;
    const confidence = rawFood.confidence;
    if (
      typeof name !== "string" || name.trim().length < 1 || name.length > 160
    ) {
      invalid("Invalid food name.");
    }
    if (
      !boundedNumber(grams, 0, 100_000) || !boundedNumber(calories, 0, 10_000)
    ) {
      invalid("Invalid food estimate.");
    }
    if (!boundedNumber(confidence, 0, 1)) invalid("Invalid confidence.");
    if (rawFood.unit !== undefined && typeof rawFood.unit !== "string") {
      invalid("Invalid food unit.");
    }
    if (
      rawFood.cooking_method !== undefined &&
      typeof rawFood.cooking_method !== "string"
    ) invalid("Invalid cooking method.");
  }
  if (!boundedNumber(value.total_estimated_calories, 0, 10_000)) {
    invalid("Invalid total calories.");
  }
  if (typeof value.notes !== "string" || value.notes.length > 1_000) {
    invalid("Invalid notes.");
  }
  if (
    value.confidence !== undefined && !boundedNumber(value.confidence, 0, 1)
  ) {
    invalid("Invalid overall confidence.");
  }
  if (value.status === "not_food" && value.foods.length !== 0) {
    invalid("Not-food response cannot contain foods.");
  }
}

function validateTextResult(
  task: AITaskType,
  value: Record<string, unknown>,
) {
  if (!["success", "out_of_scope"].includes(String(value.status))) {
    invalid("Invalid status.");
  }
  if (value.status === "out_of_scope") {
    exactKeys(value, ["status", "message"]);
    validateText(value.message);
    return;
  }
  const contentKey = task === AITaskType.dailySummary ||
      task === AITaskType.weeklySummary
    ? "summary"
    : "recommendation";
  exactKeys(value, ["status", contentKey]);
  validateText(value[contentKey]);
}

function validateText(content: unknown) {
  if (
    typeof content !== "string" || content.length < 1 || content.length > 4_000
  ) {
    invalid("Invalid text result.");
  }
}

function exactKeys(value: Record<string, unknown>, allowed: string[]) {
  const allowedSet = new Set(allowed);
  if (Object.keys(value).some((key) => !allowedSet.has(key))) {
    invalid("Unexpected response field.");
  }
}

function rejectExecutable(value: unknown) {
  if (typeof value === "string") {
    if (executableContent.some((pattern) => pattern.test(value))) {
      invalid("Executable content is not allowed.");
    }
    return;
  }
  if (Array.isArray(value)) {
    for (const item of value) rejectExecutable(item);
    return;
  }
  if (isPlainObject(value)) {
    for (const [key, nested] of Object.entries(value)) {
      if (
        ["__proto__", "prototype", "constructor", "source_code", "script"]
          .includes(key)
      ) {
        invalid("Unexpected executable field.");
      }
      rejectExecutable(nested);
    }
  }
}

function boundedNumber(
  value: unknown,
  min: number,
  max: number,
): value is number {
  return typeof value === "number" && Number.isFinite(value) && value >= min &&
    value <= max;
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function invalid(message: string): never {
  throw new AIError("invalid_response", message);
}
