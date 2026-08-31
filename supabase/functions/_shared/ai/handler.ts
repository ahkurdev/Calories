import { AIError, toAIError } from "./errors.ts";
import {
  loadOpenRouterCatalog,
  OpenRouterModelService,
} from "./openrouter_model_service.ts";
import { OpenCodeZenAIProvider } from "./providers/opencode_zen_provider.ts";
import { OpenRouterAIProvider } from "./providers/openrouter_provider.ts";
import { loadRuntimeConfig } from "./provider_config.ts";
import { AIProviderRouter } from "./provider_router.ts";
import { AIResponseNormalizer } from "./response_normalizer.ts";
import { AIScopeValidator } from "./scope_validator.ts";
import type { AIProvider, AIRequest } from "./types.ts";
import { AITaskType } from "./types.ts";

export async function handleAIRequest(
  req: Request,
  expectedTask: AITaskType,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ status: "error", message: "Method not allowed." }, 405);
  }
  try {
    const contentLength = Number(req.headers.get("content-length") ?? 0);
    if (contentLength > 14_000_000) {
      throw new AIError("out_of_scope", "Request is too large.");
    }
    const body = await req.json();
    if (!isRecord(body)) {
      throw new AIError("out_of_scope", "Structured request is required.");
    }
    if (
      body.task !== undefined &&
      AIScopeValidator.parseTask(body.task) !== expectedTask
    ) {
      throw new AIError("out_of_scope", "Task does not match this endpoint.");
    }
    const input = AIScopeValidator.validate(expectedTask, body.input);
    const request: AIRequest = {
      task: expectedTask,
      input,
      visionRequired: expectedTask === AITaskType.foodScan,
    };
    const providerResult = await createRouter().execute(request);
    return json(
      AIResponseNormalizer.normalize(expectedTask, providerResult.content),
      200,
    );
  } catch (error) {
    return errorResponse(toAIError(error));
  }
}

function createRouter(): AIProviderRouter {
  const config = loadRuntimeConfig();
  const providers: Array<{ priority: number; provider: AIProvider }> = [];
  const openRouterKey = Deno.env.get("OPENROUTER_API_KEY")?.trim() ?? "";
  if (config.openRouter.providerEnabled && openRouterKey) {
    providers.push({
      priority: config.openRouter.priority,
      provider: new OpenRouterAIProvider(
        openRouterKey,
        config.openRouter,
        new OpenRouterModelService(() => loadOpenRouterCatalog(openRouterKey)),
      ),
    });
  }
  const openCodeKey = Deno.env.get("OPENCODE_API_KEY")?.trim() ?? "";
  if (
    config.openCodeZen.providerEnabled && openCodeKey &&
    config.openCodeZen.allowedModels.length > 0
  ) {
    providers.push({
      priority: config.openCodeZen.priority,
      provider: new OpenCodeZenAIProvider(openCodeKey, config.openCodeZen),
    });
  }
  providers.sort((a, b) => a.priority - b.priority);
  return new AIProviderRouter(providers.map((item) => item.provider), {
    timeoutMs: config.openRouter.timeoutMs,
    maxRetries: config.openRouter.maxRetries,
    failureThreshold: config.circuitFailureThreshold,
    cooldownMs: config.circuitCooldownMs,
  });
}

function errorResponse(error: AIError): Response {
  if (error.code === "out_of_scope") {
    return json({
      status: "out_of_scope",
      message:
        "Fitur AI Caloris hanya dapat membantu terkait makanan, kalori, aktivitas, jadwal, dan progress.",
    }, 400);
  }
  if (error.code === "unsupported_vision") {
    return json({
      status: "error",
      error: error.code,
      message: "Foto makanan tidak didukung atau tidak valid.",
    }, 415);
  }
  if (error.code === "invalid_response") {
    return json({
      status: "error",
      error: error.code,
      message: "Respons AI tidak valid.",
    }, 502);
  }
  return json({
    status: "manual_fallback",
    error: error.code,
    message:
      "Analisis AI sedang tidak tersedia. Kamu tetap dapat memasukkan makanan secara manual.",
  }, error.code === "rate_limited" ? 429 : 503);
}

function json(body: Record<string, unknown>, status: number): Response {
  return Response.json(body, {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
