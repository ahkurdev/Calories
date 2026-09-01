import type { AIProviderConfig } from "../ai/provider_config.ts";
import { OpenRouterModelService } from "../ai/openrouter_model_service.ts";
import { OpenCodeZenAIProvider } from "../ai/providers/opencode_zen_provider.ts";
import { OpenRouterAIProvider } from "../ai/providers/openrouter_provider.ts";
import type { AIRequest } from "../ai/types.ts";
import { AITaskType } from "../ai/types.ts";

const request: AIRequest = {
  task: AITaskType.dailySummary,
  input: {
    stats: {
      date: "2026-09-01",
      targetCalories: 2000,
      consumedCalories: 1800,
      remainingCalories: 200,
      overTargetCalories: 0,
      waterMl: 2000,
      waterTargetMl: 2500,
      activityMinutes: 30,
      estimatedActivityCalories: 120,
    },
  },
  visionRequired: false,
};

function config(allowedModels: string[]): AIProviderConfig {
  return {
    providerEnabled: true,
    priority: 1,
    allowedModels,
    visionModels: [],
    timeoutMs: 20_000,
    maxRetries: 0,
    fallbackEnabled: true,
    costPolicy: "allowlisted",
    freeOnly: false,
  };
}

Deno.test("OpenRouter omits unsupported response_format and still validates output", async () => {
  let sentBody: Record<string, unknown> | undefined;
  const fetcher: typeof fetch = (_input, init) => {
    sentBody = JSON.parse(String(init?.body));
    return Promise.resolve(Response.json({
      choices: [{
        message: {
          content: '{"status":"success","summary":"Tetap konsisten."}',
        },
      }],
    }));
  };
  const models = new OpenRouterModelService(() => Promise.resolve([]));
  models.selectFromCatalog = () => [{
    id: "free/no-json-parameter",
    pricing: { prompt: "0", completion: "0" },
    supported_parameters: ["temperature"],
  }];
  const provider = new OpenRouterAIProvider(
    "test-key",
    config(["free/no-json-parameter"]),
    models,
    fetcher,
  );

  await provider.execute(request, new AbortController().signal);

  if (sentBody?.response_format !== undefined) {
    throw new Error("Unsupported response_format was sent");
  }
});

Deno.test("OpenCode routes Muse free through Responses API and parses output text", async () => {
  const urls: string[] = [];
  let sentBody: Record<string, unknown> | undefined;
  const fetcher: typeof fetch = (input, init) => {
    const url = String(input);
    urls.push(url);
    if (url.endsWith("/models")) {
      return Promise.resolve(Response.json({
        data: [{ id: "muse-spark-1.2-contributor-free" }],
      }));
    }
    sentBody = JSON.parse(String(init?.body));
    return Promise.resolve(Response.json({
      output: [{
        type: "message",
        content: [{
          type: "output_text",
          text: '{"status":"success","summary":"Hari yang baik."}',
        }],
      }],
    }));
  };
  const provider = new OpenCodeZenAIProvider(
    "test-key",
    config(["muse-spark-1.2-contributor-free"]),
    fetcher,
  );

  const result = await provider.execute(request, new AbortController().signal);

  if (!urls[1]?.endsWith("/responses")) {
    throw new Error(`Unexpected completion URL: ${urls[1]}`);
  }
  if (sentBody?.messages !== undefined || sentBody?.input === undefined) {
    throw new Error("Responses request was not translated");
  }
  if (!result.content.includes("Hari yang baik")) {
    throw new Error("Responses output was not parsed");
  }
});
