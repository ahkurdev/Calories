import type { AIErrorCode } from "./types.ts";

export class AIError extends Error {
  constructor(
    public readonly code: AIErrorCode,
    message: string,
    public readonly retryable = false,
  ) {
    super(`[${code}] ${message}`);
    this.name = "AIError";
  }
}

export function toAIError(error: unknown): AIError {
  if (error instanceof AIError) return error;
  if (error instanceof DOMException && error.name === "AbortError") {
    return new AIError("timeout", "Provider request timed out.", true);
  }
  if (error instanceof TypeError) {
    return new AIError(
      "network_error",
      "Provider network request failed.",
      true,
    );
  }
  return new AIError("unknown_error", "Unexpected AI provider failure.");
}
