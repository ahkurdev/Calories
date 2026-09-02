import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { toAIError } from "../_shared/ai/errors.ts";
import { calorisRateLimiter } from "../_shared/ai/rate_limiter.ts";
import {
  normalizeNearbyPlaces,
  validateNearbyFoodInput,
} from "../_shared/nearby_food.ts";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (!ctx.userClaims?.id) {
      return json({ status: "error", message: "Autentikasi diperlukan." }, 401);
    }
    if (!calorisRateLimiter.consume(String(ctx.userClaims.id))) {
      return json({
        status: "manual_fallback",
        message: "Terlalu banyak pencarian. Tunggu sebentar lalu coba lagi.",
      }, 429);
    }
    if (req.method !== "POST") {
      return json({ status: "error", message: "Metode tidak diizinkan." }, 405);
    }
    try {
      const body: unknown = await req.json();
      if (!isRecord(body)) throw new Error("Structured request is required.");
      const input = validateNearbyFoodInput(body.input);
      const apiKey = Deno.env.get("GOOGLE_PLACES_API_KEY")?.trim() ?? "";
      if (!apiKey) {
        return json({
          status: "configuration_required",
          message:
            "Pencarian Google Places belum dikonfigurasi. Kamu tetap dapat membuka Google Maps.",
          places: [],
        }, 503);
      }

      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 12_000);
      let response: Response;
      try {
        response = await fetch(
          "https://places.googleapis.com/v1/places:searchNearby",
          {
            method: "POST",
            signal: controller.signal,
            headers: {
              "Content-Type": "application/json",
              "X-Goog-Api-Key": apiKey,
              "X-Goog-FieldMask": [
                "places.id",
                "places.displayName",
                "places.formattedAddress",
                "places.googleMapsUri",
                "places.websiteUri",
                "places.rating",
                "places.userRatingCount",
                "places.priceLevel",
                "places.currentOpeningHours.openNow",
                "places.delivery",
                "places.takeout",
                "places.dineIn",
              ].join(","),
            },
            body: JSON.stringify({
              languageCode: "id",
              includedTypes: [
                "restaurant",
                "cafe",
                "bakery",
                "meal_takeaway",
                "meal_delivery",
              ],
              maxResultCount: 8,
              rankPreference: "DISTANCE",
              locationRestriction: {
                circle: {
                  center: {
                    latitude: input.latitude,
                    longitude: input.longitude,
                  },
                  radius: input.radiusMeters,
                },
              },
            }),
          },
        );
      } finally {
        clearTimeout(timeout);
      }
      if (!response.ok) {
        return json({
          status: "manual_fallback",
          message:
            "Tempat makan sekitar belum dapat dimuat. Coba buka Google Maps.",
          places: [],
        }, 502);
      }
      const places = normalizeNearbyPlaces(await response.json());
      return json({
        status: "success",
        message: places.length > 0
          ? "Tempat makan sekitar berhasil ditemukan."
          : "Belum ada tempat makan yang ditemukan dalam radius pencarian.",
        places,
      }, 200);
    } catch (error) {
      const normalized = toAIError(error);
      return json({
        status: normalized.code === "out_of_scope"
          ? "out_of_scope"
          : "manual_fallback",
        message: normalized.code === "out_of_scope"
          ? "Lokasi pencarian tidak valid."
          : "Tempat makan sekitar belum dapat dimuat.",
        places: [],
      }, normalized.code === "out_of_scope" ? 400 : 503);
    }
  }),
};

function json(body: Record<string, unknown>, status: number): Response {
  return Response.json(body, {
    status,
    headers: {
      "Cache-Control": "no-store",
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
