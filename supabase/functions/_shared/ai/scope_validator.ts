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
    "question",
    "conversation",
    "preferredFoods",
    "limitedFoods",
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
    switch (task) {
      case AITaskType.foodScan:
        return;
      case AITaskType.foodCalorieEstimation:
        validateFoodEstimationInput(input.foods);
        return;
      case AITaskType.foodRecommendation:
        validateFoodRecommendationInput(input);
        return;
      case AITaskType.dailySummary:
        validateDailyStats(input.stats);
        return;
      case AITaskType.weeklySummary:
        validateWeeklyStats(input.stats);
        return;
      case AITaskType.scheduleRecommendation:
        validateScheduleInput(input);
        return;
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
    let bytes: Uint8Array;
    try {
      bytes = Uint8Array.from(
        atob(value.base64),
        (character) => character.charCodeAt(0),
      );
    } catch {
      throw new AIError(
        "unsupported_vision",
        "Food image is not valid base64.",
      );
    }
    if (bytes.length === 0 || bytes.length > 10 * 1024 * 1024) {
      throw new AIError("unsupported_vision", "Food image size is invalid.");
    }
    if (!matchesImageSignature(String(value.mimeType), bytes)) {
      throw new AIError(
        "unsupported_vision",
        "Food image content does not match its media type.",
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

function matchesImageSignature(mimeType: string, bytes: Uint8Array): boolean {
  if (mimeType === "image/jpeg") {
    return bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 &&
      bytes[2] === 0xff;
  }
  if (mimeType === "image/png") {
    const signature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    return bytes.length >= signature.length &&
      signature.every((value, index) => bytes[index] === value);
  }
  return bytes.length >= 12 &&
    String.fromCharCode(...bytes.slice(0, 4)) === "RIFF" &&
    String.fromCharCode(...bytes.slice(8, 12)) === "WEBP";
}

function validateFoodEstimationInput(value: unknown) {
  if (!Array.isArray(value) || value.length < 1 || value.length > 30) {
    invalid("Structured foods are required.");
  }
  for (const food of value) {
    if (!isPlainObject(food)) invalid("Invalid food item.");
    exactKeys(food, ["name", "amount", "unit", "cookingMethod"]);
    boundedString(food.name, 1, 160, "Invalid food name.");
    boundedNumber(food.amount, 0, 100_000, "Invalid food amount.");
    boundedString(food.unit, 1, 40, "Invalid food unit.");
    optionalString(food.cookingMethod, 80, "Invalid cooking method.");
  }
}

function validateFoodRecommendationInput(input: Record<string, unknown>) {
  boundedNumber(
    input.remainingCalories,
    0,
    10_000,
    "Invalid remaining calories.",
  );
  enumString(
    input.goal,
    ["lose_weight", "maintain_weight", "gain_weight"],
    "Invalid goal.",
  );
  enumString(
    input.mealType,
    ["breakfast", "lunch", "dinner", "snack"],
    "Invalid meal type.",
  );
  optionalString(input.preference, 500, "Invalid preference.");
  optionalString(input.question, 500, "Invalid food question.");
  validateStringList(
    input.preferredFoods,
    20,
    100,
    "Invalid preferred foods.",
  );
  validateStringList(
    input.limitedFoods,
    20,
    100,
    "Invalid limited foods.",
  );
  validateFoodConversation(input.conversation);
  if (typeof input.practicalMode !== "boolean") {
    invalid("Invalid practical mode.");
  }
  if (!Array.isArray(input.foodHistory) || input.foodHistory.length > 30) {
    invalid("Invalid food history.");
  }
  for (const food of input.foodHistory) {
    if (!isPlainObject(food)) invalid("Invalid food history item.");
    exactKeys(food, ["name", "calories", "mealType"]);
    boundedString(food.name, 1, 160, "Invalid food name.");
    boundedNumber(food.calories, 0, 10_000, "Invalid food calories.");
    enumString(
      food.mealType,
      ["breakfast", "lunch", "dinner", "snack"],
      "Invalid food meal type.",
    );
  }
  validateFoodQuestionScope(input);
}

function validateFoodConversation(value: unknown) {
  if (value === undefined) return;
  if (!Array.isArray(value) || value.length > 8) {
    invalid("Invalid food conversation.");
  }
  for (const message of value) {
    if (!isPlainObject(message)) invalid("Invalid conversation message.");
    exactKeys(message, ["role", "content"]);
    enumString(
      message.role,
      ["user", "assistant"],
      "Invalid conversation role.",
    );
    boundedString(
      message.content,
      1,
      1_000,
      "Invalid conversation content.",
    );
  }
}

function validateFoodQuestionScope(input: Record<string, unknown>) {
  if (
    typeof input.question !== "string" || input.question.trim().length === 0
  ) {
    return;
  }
  const conversation = Array.isArray(input.conversation)
    ? input.conversation
      .filter(isPlainObject)
      .map((message) => String(message.content ?? ""))
      .join(" ")
    : "";
  const context = `${conversation} ${input.question}`.toLocaleLowerCase("id");
  const foodTerms =
    /\b(?:makanan?|makan|menu|kalori|kcal|porsi|nasi|lauk|sayur|buah|minum(?:an)?|sarapan|siang|malam|camilan|protein|karbohidrat|lemak|serat|diet|alergi|pantangan|boleh|batasi|hindari|masak|goreng|bakar|rebus|food|meal|calorie|portion|nutrition)\b/i;
  if (!foodTerms.test(context)) {
    invalid("Question is outside food recommendation scope.");
  }
}

function validateStringList(
  value: unknown,
  maxItems: number,
  maxLength: number,
  message: string,
) {
  if (value === undefined) return;
  if (!Array.isArray(value) || value.length > maxItems) invalid(message);
  for (const item of value) boundedString(item, 1, maxLength, message);
}

function validateDailyStats(value: unknown) {
  if (!isPlainObject(value)) invalid("Precomputed statistics are required.");
  exactKeys(value, [
    "date",
    "targetCalories",
    "consumedCalories",
    "remainingCalories",
    "overTargetCalories",
    "waterMl",
    "waterTargetMl",
    "activityMinutes",
    "estimatedActivityCalories",
  ]);
  dateString(value.date);
  for (
    const key of [
      "targetCalories",
      "consumedCalories",
      "remainingCalories",
      "overTargetCalories",
      "waterMl",
      "waterTargetMl",
      "activityMinutes",
      "estimatedActivityCalories",
    ]
  ) {
    boundedNumber(value[key], 0, 100_000, `Invalid daily statistic: ${key}.`);
  }
}

function validateWeeklyStats(value: unknown) {
  if (!isPlainObject(value)) invalid("Precomputed statistics are required.");
  exactKeys(value, [
    "periodStart",
    "periodEndInclusive",
    "periodDays",
    "targetDailyCalories",
    "averageCaloriesOnTrackedDays",
    "calorieTrackingDays",
    "averageWaterMlOnTrackedDays",
    "waterTrackingDays",
    "totalActivityMinutes",
    "activeDays",
    "weightChangeKg",
    "frequentFoods",
  ]);
  dateString(value.periodStart);
  dateString(value.periodEndInclusive);
  boundedNumber(value.periodDays, 1, 31, "Invalid period days.");
  for (
    const key of [
      "targetDailyCalories",
      "averageCaloriesOnTrackedDays",
      "calorieTrackingDays",
      "averageWaterMlOnTrackedDays",
      "waterTrackingDays",
      "totalActivityMinutes",
      "activeDays",
    ]
  ) {
    boundedNumber(value[key], 0, 100_000, `Invalid weekly statistic: ${key}.`);
  }
  if (
    value.weightChangeKg !== null && value.weightChangeKg !== undefined &&
    (typeof value.weightChangeKg !== "number" ||
      !Number.isFinite(value.weightChangeKg) ||
      value.weightChangeKg < -400 || value.weightChangeKg > 400)
  ) {
    invalid("Invalid weight change.");
  }
  if (!Array.isArray(value.frequentFoods) || value.frequentFoods.length > 5) {
    invalid("Invalid frequent foods.");
  }
  for (const food of value.frequentFoods) {
    boundedString(food, 1, 160, "Invalid frequent food.");
  }
}

function validateScheduleInput(input: Record<string, unknown>) {
  boundedNumber(input.dayOfWeek, 1, 7, "Invalid day of week.");
  if (!Number.isInteger(input.dayOfWeek)) invalid("Invalid day of week.");
  if (!Array.isArray(input.schedules) || input.schedules.length > 30) {
    invalid("Structured schedules are required.");
  }
  for (const schedule of input.schedules) {
    if (!isPlainObject(schedule)) invalid("Invalid schedule.");
    exactKeys(schedule, [
      "activityName",
      "dayOfWeek",
      "startTime",
      "endTime",
      "category",
      "busynessLevel",
    ]);
    boundedString(schedule.activityName, 1, 120, "Invalid activity name.");
    boundedNumber(schedule.dayOfWeek, 1, 7, "Invalid schedule day.");
    if (
      !Number.isInteger(schedule.dayOfWeek) ||
      schedule.dayOfWeek !== input.dayOfWeek
    ) invalid("Schedule day does not match request.");
    timeString(schedule.startTime);
    timeString(schedule.endTime);
    if (String(schedule.startTime) >= String(schedule.endTime)) {
      invalid("Invalid schedule time range.");
    }
    enumString(
      schedule.category,
      ["study", "work", "travel", "rest", "exercise", "other"],
      "Invalid schedule category.",
    );
    boundedNumber(schedule.busynessLevel, 1, 3, "Invalid busyness level.");
    if (!Number.isInteger(schedule.busynessLevel)) {
      invalid("Invalid busyness level.");
    }
  }
}

function exactKeys(value: Record<string, unknown>, allowed: string[]) {
  const allowedSet = new Set(allowed);
  if (Object.keys(value).some((key) => !allowedSet.has(key))) {
    invalid("Unexpected nested input field.");
  }
}

function boundedNumber(
  value: unknown,
  min: number,
  max: number,
  message: string,
) {
  if (
    typeof value !== "number" || !Number.isFinite(value) || value < min ||
    value > max
  ) invalid(message);
}

function boundedString(
  value: unknown,
  min: number,
  max: number,
  message: string,
) {
  if (
    typeof value !== "string" || value.trim().length < min || value.length > max
  ) {
    invalid(message);
  }
}

function optionalString(value: unknown, max: number, message: string) {
  if (
    value !== undefined && (typeof value !== "string" || value.length > max)
  ) {
    invalid(message);
  }
}

function enumString(value: unknown, allowed: string[], message: string) {
  if (typeof value !== "string" || !allowed.includes(value)) invalid(message);
}

function dateString(value: unknown) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    invalid("Invalid date.");
  }
}

function timeString(value: unknown) {
  if (
    typeof value !== "string" ||
    !/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(value)
  ) invalid("Invalid time.");
}

function invalid(message: string): never {
  throw new AIError("out_of_scope", message);
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
