import { AIError } from "./ai/errors.ts";

export interface NearbyFoodInput {
  latitude: number;
  longitude: number;
  radiusMeters: number;
}

export interface NearbyFoodPlace {
  id: string;
  name: string;
  address: string;
  mapsUri: string;
  websiteUri: string;
  rating: number | null;
  userRatingCount: number;
  priceLevel: string;
  openNow: boolean | null;
  delivery: boolean;
  takeout: boolean;
  dineIn: boolean;
}

export function validateNearbyFoodInput(value: unknown): NearbyFoodInput {
  if (!isRecord(value)) invalid("Structured location is required.");
  const keys = Object.keys(value);
  if (
    keys.some((key) => !["latitude", "longitude", "radiusMeters"].includes(key))
  ) {
    invalid("Unexpected location field.");
  }
  const latitude = boundedNumber(value.latitude, -90, 90);
  const longitude = boundedNumber(value.longitude, -180, 180);
  const radiusMeters = boundedNumber(value.radiusMeters, 300, 3_000);
  return { latitude, longitude, radiusMeters };
}

export function normalizeNearbyPlaces(raw: unknown): NearbyFoodPlace[] {
  if (!isRecord(raw) || !Array.isArray(raw.places)) return [];
  const places: NearbyFoodPlace[] = [];
  for (const value of raw.places.slice(0, 8)) {
    if (!isRecord(value)) continue;
    const displayName = isRecord(value.displayName)
      ? safeString(value.displayName.text, 120)
      : "";
    const mapsUri = safeUrl(value.googleMapsUri, true);
    if (!displayName || !mapsUri) continue;
    const openingHours = isRecord(value.currentOpeningHours)
      ? value.currentOpeningHours
      : {};
    places.push({
      id: safeString(value.id, 160),
      name: displayName,
      address: safeString(value.formattedAddress, 300),
      mapsUri,
      websiteUri: safeUrl(value.websiteUri, false),
      rating: typeof value.rating === "number" && value.rating >= 0 &&
          value.rating <= 5
        ? value.rating
        : null,
      userRatingCount: typeof value.userRatingCount === "number" &&
          Number.isInteger(value.userRatingCount) && value.userRatingCount >= 0
        ? Math.min(value.userRatingCount, 10_000_000)
        : 0,
      priceLevel: safeString(value.priceLevel, 60),
      openNow: typeof openingHours.openNow === "boolean"
        ? openingHours.openNow
        : null,
      delivery: value.delivery === true,
      takeout: value.takeout === true,
      dineIn: value.dineIn === true,
    });
  }
  return places;
}

function safeUrl(value: unknown, googleMapsOnly: boolean): string {
  if (typeof value !== "string" || value.length > 2_000) return "";
  try {
    const url = new URL(value);
    if (url.protocol !== "https:") return "";
    if (
      googleMapsOnly &&
      !["maps.google.com", "www.google.com", "maps.app.goo.gl"].includes(
        url.hostname,
      )
    ) return "";
    return url.toString();
  } catch {
    return "";
  }
}

function safeString(value: unknown, maxLength: number): string {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, maxLength);
}

function boundedNumber(value: unknown, min: number, max: number): number {
  if (
    typeof value !== "number" || !Number.isFinite(value) || value < min ||
    value > max
  ) invalid("Invalid nearby-food coordinate or radius.");
  return value;
}

function invalid(message: string): never {
  throw new AIError("out_of_scope", message);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
