import { AIError } from "./errors.ts";
import { AITaskType } from "./types.ts";

const taskValues = new Set<string>(Object.values(AITaskType));
const dangerousContent = [
  /ignore\s+(all\s+)?previous\s+instructions?/i,
  /reveal\s+(the\s+)?system\s+prompt/i,
  /(?:write|generate|create|debug|fix)\s+(?:some\s+)?(?:source\s+)?(?:code|sql|python|javascript|dart|java|website|app)/i,
  /(?:execute|run)\s+(?:this\s+)?(?:shell\s+)?command/i,
  /(?:terminal|filesystem|repository|hacking|cryptocurrency|politics)/i,
];

const allowedKeys: Record<AITaskType, ReadonlySet<string>> = {
  [AITaskType.foodScan]: new Set(["image", "mealContext"]),
  [AITaskType.foodCalorieEstimation]: new Set(["foods"]),
  [AITaskType.foodRecommendation]: new Set([
    "remainingCalories",
    "goal",
    "mealType",
    "preference",
    "foodHistory",
    "practicalMode",
  ]),
  [AITaskType.dailySummary]: new Set(["stats"]),
  [AITaskType.weeklySummary]: new Set(["stats"]),
  [AITaskType.scheduleRecommendation]: new Set(["schedules", "dayOfWeek"]),
};

export class AIScopeValidator {
  static parseTask(value: unknown): AITaskType {
    if (typeof value !== "string" || !taskValues.has(value)) {
      throw new AIError("out_of_scope", "Task is not allowed.");
    }
    return value as AITaskType;
  }

  static validate(task: AITaskType, input: unknown): Record<string, unknown> {
    if (!isPlainObject(input)) {
      throw new AIError("out_of_scope", "Structured input is required.");
    }
    const serialized = JSON.stringify(input);
    if (new TextEncoder().encode(serialized).byteLength > 14_000_000) {
      throw new AIError("out_of_scope", "Input is too large.");
    }
    const allowed = allowedKeys[task];
    if (Object.keys(input).some((key) => !allowed.has(key))) {
      throw new AIError("out_of_scope", "Unexpected input field.");
    }
    this.rejectDangerousContent(input);
    if (task === AITaskType.foodScan) this.validateImage(input.image);
    this.validateRequiredFields(task, input);
    return input;
  }

  private static validateRequiredFields(
    task: AITaskType,
    input: Record<string, unknown>,
  ) {
    if (task === AITaskType.foodRecommendation) {
      const calories = input.remainingCalories;
      if (typeof calories !== "number" || calories < 0 || calories > 10_000) {
        throw new AIError("out_of_scope", "Invalid remaining calories.");
      }
    }
    if (
      (task === AITaskType.dailySummary || task === AITaskType.weeklySummary) &&
      !isPlainObject(input.stats)
    ) {
      throw new AIError("out_of_scope", "Precomputed statistics are required.");
    }
    if (
      task === AITaskType.scheduleRecommendation &&
      !Array.isArray(input.schedules)
    ) {
      throw new AIError("out_of_scope", "Structured schedules are required.");
    }
  }

  private static validateImage(value: unknown) {
    if (!isPlainObject(value)) {
      throw new AIError("unsupported_vision", "A food image is required.");
    }
    const keys = Object.keys(value);
    if (keys.some((key) => !["mimeType", "base64"].includes(key))) {
      throw new AIError("out_of_scope", "Unexpected image field.");
    }
    if (
      !["image/jpeg", "image/png", "image/webp"].includes(
        String(value.mimeType),
      )
    ) {
      throw new AIError("unsupported_vision", "Unsupported food image type.");
    }
    if (typeof value.base64 !== "string" || value.base64.length < 4) {
      throw new AIError("unsupported_vision", "Food image data is missing.");
    }
    if (
      value.base64.length > 13_981_016 ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(value.base64)
    ) {
      throw new AIError(
        "unsupported_vision",
        "Food image is invalid or too large.",
      );
    }
  }

  private static rejectDangerousContent(value: unknown, key?: string) {
    if (key === "base64") return;
    if (typeof value === "string") {
      if (
        value.length > 4_000 ||
        dangerousContent.some((pattern) => pattern.test(value))
      ) {
        throw new AIError("out_of_scope", "Input is outside Caloris scope.");
      }
      return;
    }
    if (Array.isArray(value)) {
      if (value.length > 100) {
        throw new AIError("out_of_scope", "Input list is too large.");
      }
      for (const item of value) this.rejectDangerousContent(item);
      return;
    }
    if (isPlainObject(value)) {
      for (const [nestedKey, nestedValue] of Object.entries(value)) {
        this.rejectDangerousContent(nestedValue, nestedKey);
      }
    }
  }
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
