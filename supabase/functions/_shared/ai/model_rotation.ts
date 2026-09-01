const rotationIndexes = new Map<string, number>();

export function rotatingModelWindow(
  poolKey: string,
  models: readonly string[],
  maxAttempts: number,
): string[] {
  if (models.length === 0 || maxAttempts <= 0) return [];
  const start = (rotationIndexes.get(poolKey) ?? 0) % models.length;
  rotationIndexes.set(poolKey, (start + 1) % models.length);
  const rotated = [...models.slice(start), ...models.slice(0, start)];
  return rotated.slice(0, Math.min(maxAttempts, models.length));
}

export function resetModelRotationForTests() {
  rotationIndexes.clear();
}
