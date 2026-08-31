export enum AITaskType {
  foodScan = "food_scan",
  foodCalorieEstimation = "food_calorie_estimation",
  foodRecommendation = "food_recommendation",
  dailySummary = "daily_summary",
  weeklySummary = "weekly_summary",
  scheduleRecommendation = "schedule_recommendation",
}

export type AIErrorCode =
  | "provider_unavailable"
  | "model_unavailable"
  | "rate_limited"
  | "timeout"
  | "invalid_response"
  | "unsupported_vision"
  | "out_of_scope"
  | "network_error"
  | "unknown_error";

export interface AIRequest {
  task: AITaskType;
  input: Record<string, unknown>;
  visionRequired: boolean;
}

export interface AIProviderResult {
  provider: "openrouter" | "opencode_zen";
  model: string;
  content: string;
}

export interface AIProvider {
  readonly name: AIProviderResult["provider"];
  execute(request: AIRequest, signal: AbortSignal): Promise<AIProviderResult>;
}
