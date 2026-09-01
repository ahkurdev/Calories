import { AIError } from "../errors.ts";
import { rotatingModelWindow } from "../model_rotation.ts";
import type { AIProviderConfig } from "../provider_config.ts";
import { AIResponseNormalizer } from "../response_normalizer.ts";
import { buildMessages } from "../system_prompt.ts";
import type { AIProvider, AIProviderResult, AIRequest } from "../types.ts";

const responsesModels = new Set(["muse-spark-1.2-contributor-free"]);

export class OpenCodeZenAIProvider implements AIProvider {
  readonly name = "opencode_zen" as const;

  constructor(
    private readonly apiKey: string,
    private readonly config: AIProviderConfig,
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  async execute(
    request: AIRequest,
    signal: AbortSignal,
  ): Promise<AIProviderResult> {
    const models = await this.availableAllowedModels(signal);
    const compatible = request.visionRequired
      ? models.filter((model) => this.config.visionModels.includes(model))
      : models;
    if (compatible.length === 0) {
      throw new AIError(
        request.visionRequired ? "unsupported_vision" : "model_unavailable",
        "No explicitly allowed OpenCode Zen model is available.",
        true,
      );
    }
    let lastError: AIError | undefined;
    const selectedModels = rotatingModelWindow(
      `opencode:${request.visionRequired ? "vision" : "text"}`,
      compatible,
      3,
    );
    for (const model of selectedModels) {
      try {
        const responsesApi = responsesModels.has(model);
        const response = await this.fetcher(
          responsesApi
            ? "https://opencode.ai/zen/v1/responses"
            : "https://opencode.ai/zen/v1/chat/completions",
          {
            method: "POST",
            signal,
            headers: {
              Authorization: `Bearer ${this.apiKey}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(
              responsesApi ? buildResponsesRequest(model, request) : {
                model,
                messages: buildMessages(request),
                response_format: { type: "json_object" },
                temperature: 0.2,
                max_tokens: 1800,
              },
            ),
          },
        );
        if (!response.ok) throw mapStatus(response.status);
        const content = responsesApi
          ? parseOpenCodeResponsesResponse(await response.json())
          : parseOpenCodeResponse(await response.json());
        AIResponseNormalizer.normalize(request.task, content);
        return {
          provider: this.name,
          model,
          content,
        };
      } catch (error) {
        lastError = error instanceof AIError
          ? error
          : error instanceof DOMException && error.name === "AbortError"
          ? new AIError("timeout", "OpenCode Zen timed out.", true)
          : new AIError("network_error", "OpenCode Zen network failed.", true);
        if (!lastError.retryable && lastError.code !== "invalid_response") {
          throw lastError;
        }
      }
    }
    throw lastError ??
      new AIError("model_unavailable", "OpenCode Zen models failed.", true);
  }

  private async availableAllowedModels(signal: AbortSignal): Promise<string[]> {
    if (this.config.allowedModels.length === 0) return [];
    const response = await this.fetcher("https://opencode.ai/zen/v1/models", {
      signal,
      headers: { Authorization: `Bearer ${this.apiKey}` },
    });
    if (!response.ok) {
      throw new AIError(
        "provider_unavailable",
        "OpenCode Zen catalog unavailable.",
        true,
      );
    }
    const payload = await response.json();
    if (!isRecord(payload) || !Array.isArray(payload.data)) {
      throw new AIError(
        "invalid_response",
        "Invalid OpenCode Zen model catalog.",
      );
    }
    const available = new Set(
      payload.data.filter(isRecord).map((model) => model.id).filter((
        id,
      ): id is string => typeof id === "string"),
    );
    return this.config.allowedModels.filter((model) => available.has(model));
  }
}

function buildResponsesRequest(model: string, request: AIRequest) {
  const messages = buildMessages(request);
  const instructions = messages.find((message) => message.role === "system")
    ?.content;
  const input = messages.filter((message) => message.role !== "system").map(
    (message) => ({ role: message.role, content: message.content }),
  );
  return {
    model,
    instructions,
    input,
    text: { format: { type: "json_object" } },
    temperature: 0.2,
    max_output_tokens: 1800,
  };
}

export function parseOpenCodeResponse(payload: unknown): string {
  if (!isRecord(payload) || !Array.isArray(payload.choices)) invalid();
  const first = payload.choices[0];
  if (
    !isRecord(first) || !isRecord(first.message) ||
    typeof first.message.content !== "string"
  ) invalid();
  if (first.message.content.length > 32_768) invalid();
  return first.message.content;
}

export function parseOpenCodeResponsesResponse(payload: unknown): string {
  if (!isRecord(payload)) invalid();
  if (typeof payload.output_text === "string") {
    if (payload.output_text.length > 32_768) invalid();
    return payload.output_text;
  }
  if (!Array.isArray(payload.output)) invalid();
  const text = payload.output.flatMap((item) => {
    if (!isRecord(item) || !Array.isArray(item.content)) return [];
    return item.content.flatMap((content) =>
      isRecord(content) && typeof content.text === "string"
        ? [content.text]
        : []
    );
  }).join("");
  if (text.length < 1 || text.length > 32_768) invalid();
  return text;
}

function mapStatus(status: number): AIError {
  if (status === 429) {
    return new AIError("rate_limited", "OpenCode Zen rate limited.", true);
  }
  if (status >= 500) {
    return new AIError(
      "provider_unavailable",
      "OpenCode Zen unavailable.",
      true,
    );
  }
  if (status === 400 || status === 404) {
    return new AIError(
      "model_unavailable",
      "OpenCode Zen model unavailable.",
      true,
    );
  }
  return new AIError("provider_unavailable", "OpenCode Zen request rejected.");
}

function invalid(): never {
  throw new AIError("invalid_response", "Invalid OpenCode Zen response.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
