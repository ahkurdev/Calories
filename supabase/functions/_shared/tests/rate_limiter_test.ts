import { InMemoryRateLimiter } from "../ai/rate_limiter.ts";

Deno.test("rate limiter bounds requests per authenticated user and window", () => {
  const limiter = new InMemoryRateLimiter(2, 60_000);

  if (!limiter.consume("user-a", 1_000)) throw new Error("first rejected");
  if (!limiter.consume("user-a", 2_000)) throw new Error("second rejected");
  if (limiter.consume("user-a", 3_000)) throw new Error("limit not enforced");
  if (!limiter.consume("user-b", 3_000)) throw new Error("users not isolated");
  if (!limiter.consume("user-a", 61_001)) throw new Error("window not reset");
});
