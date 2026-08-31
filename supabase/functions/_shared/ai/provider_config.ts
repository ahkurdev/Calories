export interface AIProviderConfig {
  providerEnabled: boolean;
  priority: number;
  allowedModels: string[];
  visionModels: string[];
  timeoutMs: number;
  maxRetries: number;
  fallbackEnabled: boolean;
  costPolicy: "free_only" | "allowlisted";
  freeOnly: boolean;
}

export interface AIRuntimeConfig {
  openRouter: AIProviderConfig;
  openCodeZen: AIProviderConfig;
  circuitFailureThreshold: number;
  circuitCooldownMs: number;
}

export function loadRuntimeConfig(
  env: (key: string) => string | undefined = Deno.env.get,
): AIRuntimeConfig {
  const openRouterKey = env("OPENROUTER_API_KEY")?.trim() ?? "";
  const openCodeKey = env("OPENCODE_API_KEY")?.trim() ?? "";
  return {
    openRouter: {
      providerEnabled: openRouterKey.length > 0 &&
        env("OPENROUTER_ENABLED") !== "false",
      priority: numberEnv(env("OPENROUTER_PRIORITY"), 1, 1, 10),
      allowedModels: csv(env("OPENROUTER_ALLOWED_MODELS")),
      visionModels: [],
      timeoutMs: numberEnv(env("AI_TIMEOUT_MS"), 20_000, 1_000, 60_000),
      maxRetries: numberEnv(env("AI_MAX_RETRIES"), 1, 0, 2),
      fallbackEnabled: true,
      costPolicy: "free_only",
      freeOnly: true,
    },
    openCodeZen: {
      providerEnabled: openCodeKey.length > 0 &&
        env("OPENCODE_ENABLED") !== "false",
      priority: numberEnv(env("OPENCODE_PRIORITY"), 2, 1, 10),
      allowedModels: csv(env("OPENCODE_ALLOWED_MODELS")),
      visionModels: csv(env("OPENCODE_VISION_MODELS")),
      timeoutMs: numberEnv(env("AI_TIMEOUT_MS"), 20_000, 1_000, 60_000),
      maxRetries: numberEnv(env("AI_MAX_RETRIES"), 1, 0, 2),
      fallbackEnabled: true,
      costPolicy: "allowlisted",
      freeOnly: false,
    },
    circuitFailureThreshold: numberEnv(
      env("AI_CIRCUIT_FAILURE_THRESHOLD"),
      3,
      1,
      10,
    ),
    circuitCooldownMs: numberEnv(
      env("AI_CIRCUIT_COOLDOWN_MS"),
      60_000,
      1_000,
      600_000,
    ),
  };
}

function csv(value: string | undefined): string[] {
  return [
    ...new Set(
      (value ?? "").split(",").map((item) => item.trim()).filter(Boolean),
    ),
  ];
}

function numberEnv(
  value: string | undefined,
  fallback: number,
  min: number,
  max: number,
): number {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= min && parsed <= max
    ? parsed
    : fallback;
}
