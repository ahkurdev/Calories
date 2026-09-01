import { AIError, toAIError } from "../errors.ts";
import { rotatingModelWindow } from "../model_rotation.ts";
import { OpenRouterModelService } from "../openrouter_model_service.ts";
import type { AIProviderConfig } from "../provider_config.ts";
import { AIResponseNormalizer } from "../response_normalizer.ts";
import { buildMessages } from "../system_prompt.ts";
import type { AIProvider, AIProviderResult, AIRequest } from "../types.ts";

export class OpenRouterAIProvider implements AIProvider {
  readonly name = "openrouter" as const;

  constructor(
    private readonly apiKey: string,
    private readonly config: AIProviderConfig,
    private readonly models: OpenRouterModelService,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async execute(
    request: AIRequest,
    signal: AbortSignal,
  ): Promise<AIProviderResult> {
    const models = await this.models.compatibleModels({
      visionRequired: request.visionRequired,
      allowedModels: this.config.allowedModels,
    });
    if (models.length === 0) {
      throw new AIError(
        request.visionRequired ? "unsupported_vision" : "model_unavailable",
        "No compatible free OpenRouter model is available.",
        true,
      );
    }
    let lastError: AIError | undefined;
    const selectedIds = rotatingModelWindow(
      `openrouter:${request.visionRequired ? "vision" : "text"}`,
      models.map((model) => model.id),
      3,
    );
    const byId = new Map(models.map((model) => [model.id, model]));
    for (const modelId of selectedIds) {
      const model = byId.get(modelId)!;
      try {
        const supportsJsonParameter = (model.supported_parameters ?? []).some(
          (parameter) =>
            parameter === "structured_outputs" ||
            parameter === "response_format",
        );
        const response = await this.fetcher(
          "https://openrouter.ai/api/v1/chat/completions",
          {
            method: "POST",
            signal,
            headers: {
              Authorization: `Bearer ${this.apiKey}`,
              "Content-Type": "application/json",
              "HTTP-Referer": "https://caloris.app",
              "X-Title": "Caloris",
            },
            body: JSON.stringify({
              model: model.id,
              messages: buildMessages(request),
              ...(supportsJsonParameter
                ? { response_format: { type: "json_object" } }
                : {}),
              temperature: 0.2,
              max_tokens: 1800,
            }),
          },
        );
        if (!response.ok) throw mapStatus(response.status, "OpenRouter");
        const content = parseOpenRouterResponse(await response.json());
        AIResponseNormalizer.normalize(request.task, content);
        return { provider: this.name, model: model.id, content };
      } catch (error) {
        lastError = toAIError(error);
        if (!lastError.retryable && lastError.code !== "invalid_response") {
          throw lastError;
        }
      }
    }
    throw lastError ??
      new AIError("model_unavailable", "OpenRouter models failed.", true);
  }
}

export function parseOpenRouterResponse(payload: unknown): string {
  if (!isRecord(payload) || !Array.isArray(payload.choices)) invalid();
  const first = payload.choices[0];
  if (
    !isRecord(first) || !isRecord(first.message) ||
    typeof first.message.content !== "string"
  ) invalid();
  if (first.message.content.length > 32_768) invalid();
  return first.message.content;
}

function mapStatus(status: number, provider: string): AIError {
  if (status === 429) {
    return new AIError("rate_limited", `${provider} rate limited.`, true);
  }
  if (status >= 500) {
    return new AIError(
      "provider_unavailable",
      `${provider} unavailable.`,
      true,
    );
  }
  if (status === 400 || status === 404) {
    return new AIError(
      "model_unavailable",
      `${provider} model unavailable.`,
      true,
    );
  }
  return new AIError("provider_unavailable", `${provider} request rejected.`);
}

function invalid(): never {
  throw new AIError("invalid_response", "Invalid OpenRouter response.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
