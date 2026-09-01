interface Bucket {
  count: number;
  windowStartedAt: number;
}

export class InMemoryRateLimiter {
  private readonly buckets = new Map<string, Bucket>();

  constructor(
    private readonly limit: number,
    private readonly windowMs: number,
  ) {
    if (limit < 1 || windowMs < 1) throw new Error("Invalid rate limit.");
  }

  consume(key: string, now = Date.now()): boolean {
    const existing = this.buckets.get(key);
    if (!existing || now - existing.windowStartedAt >= this.windowMs) {
      this.buckets.set(key, { count: 1, windowStartedAt: now });
      this.prune(now);
      return true;
    }
    if (existing.count >= this.limit) return false;
    existing.count += 1;
    return true;
  }

  private prune(now: number) {
    if (this.buckets.size < 1_000) return;
    for (const [key, bucket] of this.buckets) {
      if (now - bucket.windowStartedAt >= this.windowMs) {
        this.buckets.delete(key);
      }
    }
  }
}

export const calorisRateLimiter = new InMemoryRateLimiter(
  integerEnv("AI_RATE_LIMIT_PER_MINUTE", 12, 1, 60),
  60_000,
);

function integerEnv(key: string, fallback: number, min: number, max: number) {
  const value = Number(Deno.env.get(key));
  return Number.isInteger(value) && value >= min && value <= max
    ? value
    : fallback;
}
