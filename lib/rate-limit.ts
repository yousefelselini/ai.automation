const bucket = new Map<string, { count: number; resetAt: number }>();
export function checkRateLimit(key: string, limit = 20, windowMs = 60_000) {
  const now = Date.now(); const entry = bucket.get(key);
  if (!entry || entry.resetAt < now) { bucket.set(key, { count: 1, resetAt: now + windowMs }); return true; }
  if (entry.count >= limit) return false;
  entry.count += 1; return true;
}
