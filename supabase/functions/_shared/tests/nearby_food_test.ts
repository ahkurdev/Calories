import {
  normalizeNearbyPlaces,
  validateNearbyFoodInput,
} from "../nearby_food.ts";

function assertThrows(fn: () => unknown) {
  try {
    fn();
    throw new Error("Expected function to throw");
  } catch (error) {
    if (!(error instanceof Error) || !error.message.includes("out_of_scope")) {
      throw error;
    }
  }
}

Deno.test("nearby food input accepts only bounded coordinates and radius", () => {
  const input = validateNearbyFoodInput({
    latitude: -6.2,
    longitude: 106.816,
    radiusMeters: 1500,
  });
  if (input.radiusMeters !== 1500) throw new Error("Unexpected radius");

  assertThrows(() =>
    validateNearbyFoodInput({
      latitude: -6.2,
      longitude: 106.816,
      radiusMeters: 1500,
      userId: "private",
    })
  );
  assertThrows(() =>
    validateNearbyFoodInput({
      latitude: 120,
      longitude: 106.816,
      radiusMeters: 1500,
    })
  );
});

Deno.test("nearby place normalizer returns a bounded safe public shape", () => {
  const places = normalizeNearbyPlaces({
    places: [{
      id: "place-1",
      displayName: { text: "Warung Sehat" },
      formattedAddress: "Jalan Contoh 1",
      googleMapsUri: "https://maps.google.com/?cid=1",
      websiteUri: "https://warung.example/menu",
      rating: 4.5,
      userRatingCount: 120,
      currentOpeningHours: { openNow: true },
      delivery: true,
      takeout: true,
      dineIn: false,
      priceLevel: "PRICE_LEVEL_MODERATE",
    }],
  });

  if (places.length !== 1 || places[0].name !== "Warung Sehat") {
    throw new Error("Unexpected places");
  }
  if (places[0].mapsUri !== "https://maps.google.com/?cid=1") {
    throw new Error("Unexpected maps URI");
  }
});
