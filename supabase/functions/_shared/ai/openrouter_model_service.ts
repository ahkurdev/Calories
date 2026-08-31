import { AIError } from "./errors.ts";

export interface OpenRouterModel {
  id: string;
  architecture?: { input_modalities?: string[] };
  pricing?: Record<string, string | number | undefined>;
  supported_parameters?: string[];
  context_length?: number;
}

interface SelectionOptions {
  visionRequired: boolean;
  allowedModels: string[];
}

export class OpenRouterModelService {
  private cache?: { expiresAt: number; models: OpenRouterModel[] };

  constructor(
    private readonly loader: () => Promise<OpenRouterModel[]>,
    private readonly cacheMs = 5 * 60_000,
  ) {}

  async compatibleModels(
    options: SelectionOptions,
  ): Promise<OpenRouterModel[]> {
    const now = Date.now();
    if (!this.cache || this.cache.expiresAt <= now) {
      this.cache = {
        models: await this.loader(),
        expiresAt: now + this.cacheMs,
      };
    }
    return this.selectFromCatalog(this.cache.models, options);
  }

  selectFromCatalog(
    catalog: OpenRouterModel[],
    options: SelectionOptions,
  ): OpenRouterModel[] {
    const allowed = new Set(options.allowedModels);
    return catalog.filter((model) => {
      if (!model.id || (allowed.size > 0 && !allowed.has(model.id))) {
        return false;
      }
      if (!isFree(model.pricing)) return false;
      if (
        options.visionRequired &&
        !model.architecture?.input_modalities?.includes("image")
      ) return false;
      const parameters = model.supported_parameters ?? [];
      return parameters.includes("structured_outputs") ||
        parameters.includes("response_format");
    }).sort((a, b) => (b.context_length ?? 0) - (a.context_length ?? 0));
  }
}

export async function loadOpenRouterCatalog(
  apiKey: string,
  fetcher: typeof fetch = fetch,
): Promise<OpenRouterModel[]> {
  const response = await fetcher("https://openrouter.ai/api/v1/models", {
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  if (!response.ok) {
    throw new AIError(
      "provider_unavailable",
      "OpenRouter model catalog unavailable.",
      true,
    );
  }
  const payload = await response.json();
  if (!isRecord(payload) || !Array.isArray(payload.data)) {
    throw new AIError("invalid_response", "Invalid OpenRouter model catalog.");
  }
  return payload.data as OpenRouterModel[];
}

function isFree(pricing: OpenRouterModel["pricing"]): boolean {
  if (!pricing) return false;
  if (!zero(pricing.prompt) || !zero(pricing.completion)) return false;
  return [pricing.request, pricing.image].every((value) =>
    value === undefined || zero(value)
  );
}

function zero(value: string | number | undefined): boolean {
  if (value === undefined || value === "") return false;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed === 0;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
