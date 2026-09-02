import 'package:caloris/features/recommendations/domain/recommendation_models.dart';

class NearbyFoodParser {
  const NearbyFoodParser._();

  static NearbyFoodSearchResult parse(Map<String, Object?> json) {
    final status = switch (json['status']) {
      'success' => NearbyFoodStatus.success,
      'configuration_required' => NearbyFoodStatus.configurationRequired,
      _ => NearbyFoodStatus.unavailable,
    };
    final message = _text(json['message'], 500);
    final rawPlaces = json['places'];
    final places = <NearbyFoodPlace>[];
    if (rawPlaces is List<Object?>) {
      for (final raw in rawPlaces.take(8)) {
        if (raw is! Map<Object?, Object?>) continue;
        final name = _text(raw['name'], 120);
        final mapsUri = _safeUrl(raw['mapsUri'], googleMapsOnly: true);
        if (name.isEmpty || mapsUri.isEmpty) continue;
        final rating = raw['rating'];
        places.add(
          NearbyFoodPlace(
            id: _text(raw['id'], 160),
            name: name,
            address: _text(raw['address'], 300),
            mapsUri: mapsUri,
            websiteUri: _safeUrl(raw['websiteUri']),
            rating: rating is num && rating >= 0 && rating <= 5
                ? rating.toDouble()
                : null,
            userRatingCount: switch (raw['userRatingCount']) {
              final int count when count >= 0 => count,
              _ => 0,
            },
            priceLevel: _text(raw['priceLevel'], 60),
            openNow: raw['openNow'] is bool ? raw['openNow']! as bool : null,
            delivery: raw['delivery'] == true,
            takeout: raw['takeout'] == true,
            dineIn: raw['dineIn'] == true,
          ),
        );
      }
    }
    return NearbyFoodSearchResult(
      status: status,
      message: message.isEmpty
          ? 'Tempat makan sekitar belum dapat dimuat.'
          : message,
      places: List.unmodifiable(places),
    );
  }

  static String _safeUrl(Object? value, {bool googleMapsOnly = false}) {
    if (value is! String || value.length > 2000) return '';
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return '';
    if (googleMapsOnly &&
        !const {
          'maps.google.com',
          'www.google.com',
          'maps.app.goo.gl',
        }.contains(uri.host)) {
      return '';
    }
    return uri.toString();
  }

  static String _text(Object? value, int maxLength) {
    if (value is! String) return '';
    return value.trim().substring(0, value.trim().length.clamp(0, maxLength));
  }
}
