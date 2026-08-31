import { withSupabase } from "@supabase/server";
import { handleAIRequest } from "./handler.ts";
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
      return await handleAIRequest(req, task);
    }),
  };
}
