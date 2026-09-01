import { withSupabase } from "@supabase/server";
import { handleAIRequest } from "./handler.ts";
import { calorisRateLimiter } from "./rate_limiter.ts";
import type { AITaskType } from "./types.ts";

export function createCalorisFunction(task: AITaskType) {
  return {
    fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
      if (!ctx.userClaims?.id) {
        return Response.json(
          { status: "error", message: "Authentication required." },
          { status: 401 },
        );
      }
      if (!calorisRateLimiter.consume(String(ctx.userClaims.id))) {
        return Response.json(
          {
            status: "manual_fallback",
            error: "rate_limited",
            message:
              "Terlalu banyak permintaan insight. Tunggu sebentar lalu coba lagi.",
          },
          {
            status: 429,
            headers: {
              "Cache-Control": "no-store",
              "Retry-After": "60",
              "X-Content-Type-Options": "nosniff",
            },
          },
        );
      }
      return await handleAIRequest(req, task);
    }),
  };
}
