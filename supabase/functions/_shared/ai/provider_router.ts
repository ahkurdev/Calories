import { AIError, toAIError } from "./errors.ts";
import type { AIProvider, AIProviderResult, AIRequest } from "./types.ts";

interface RouterOptions {
  timeoutMs: number;
  maxRetries: number;
  failureThreshold: number;
  cooldownMs: number;
}

interface CircuitState {
  failures: number;
  openUntil: number;
}

export class AIProviderRouter {
  private readonly circuits = new Map<string, CircuitState>();

  constructor(
    private readonly providers: AIProvider[],
    private readonly options: RouterOptions,
  ) {}

  async execute(request: AIRequest): Promise<AIProviderResult> {
    let lastError: AIError | undefined;
    for (const provider of this.providers) {
      if (this.isCircuitOpen(provider.name)) continue;
      for (let attempt = 0; attempt <= this.options.maxRetries; attempt++) {
        try {
          const result = await this.withTimeout(provider, request);
          this.circuits.delete(provider.name);
          return result;
        } catch (error) {
          lastError = toAIError(error);
          if (!lastError.retryable) break;
        }
      }
      this.recordFailure(provider.name);
    }
    throw lastError ??
      new AIError("provider_unavailable", "No AI provider is configured.");
  }

  private async withTimeout(
    provider: AIProvider,
    request: AIRequest,
  ): Promise<AIProviderResult> {
    const controller = new AbortController();
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      return await Promise.race([
        provider.execute(request, controller.signal),
        new Promise<never>((_, reject) => {
          timer = setTimeout(() => {
            controller.abort();
            reject(new AIError("timeout", `${provider.name} timed out.`, true));
          }, this.options.timeoutMs);
        }),
      ]);
    } finally {
      if (timer !== undefined) clearTimeout(timer);
    }
  }

  private isCircuitOpen(name: string): boolean {
    const state = this.circuits.get(name);
    if (!state) return false;
    if (state.openUntil > Date.now()) return true;
    if (state.openUntil > 0) this.circuits.delete(name);
    return false;
  }

  private recordFailure(name: string) {
    const previous = this.circuits.get(name) ?? { failures: 0, openUntil: 0 };
    const failures = previous.failures + 1;
    this.circuits.set(name, {
      failures,
      openUntil: failures >= this.options.failureThreshold
        ? Date.now() + this.options.cooldownMs
        : 0,
    });
  }
}
