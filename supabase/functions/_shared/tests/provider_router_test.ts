import { AIError } from "../ai/errors.ts";
import { AIProviderRouter } from "../ai/provider_router.ts";
import type { AIProvider, AIRequest } from "../ai/types.ts";
import { AITaskType } from "../ai/types.ts";

const request: AIRequest = {
  task: AITaskType.dailySummary,
  input: { stats: { calories: 1800 } },
  visionRequired: false,
};

Deno.test("provider router falls back after a retryable provider error", async () => {
  const attempts: string[] = [];
  const first: AIProvider = {
    name: "openrouter",
    execute: () => {
      attempts.push("openrouter");
      throw new AIError("rate_limited", "limited", true);
    },
  };
  const second: AIProvider = {
    name: "opencode_zen",
    execute: () => {
      attempts.push("opencode_zen");
      return Promise.resolve({
        provider: "opencode_zen",
        model: "allowed-model",
        content: '{"status":"success","summary":"Baik."}',
      });
    },
  };
  const router = new AIProviderRouter([first, second], {
    timeoutMs: 100,
    maxRetries: 0,
    failureThreshold: 2,
    cooldownMs: 1_000,
  });

  const result = await router.execute(request);
  if (result.provider !== "opencode_zen") throw new Error("Fallback failed");
  if (attempts.join(",") !== "openrouter,opencode_zen") {
    throw new Error(`Unexpected attempts: ${attempts}`);
  }
});

Deno.test("provider router bounds timeout and opens circuit after failures", async () => {
  let attempts = 0;
  const slow: AIProvider = {
    name: "openrouter",
    execute: (_request, signal) =>
      new Promise((_resolve, reject) => {
        attempts++;
        signal.addEventListener("abort", () =>
          reject(new DOMException("Aborted", "AbortError")));
      }),
  };
  const router = new AIProviderRouter([slow], {
    timeoutMs: 5,
    maxRetries: 0,
    failureThreshold: 1,
    cooldownMs: 60_000,
  });
  for (let index = 0; index < 2; index++) {
    try {
      await router.execute(request);
    } catch {
      // Expected provider_unavailable after timeout or an open circuit.
    }
  }
  if (attempts !== 1) throw new Error(`Circuit did not open: ${attempts}`);
});
