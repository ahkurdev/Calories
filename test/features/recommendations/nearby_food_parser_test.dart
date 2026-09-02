import 'package:caloris/features/recommendations/services/nearby_food_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses bounded nearby places and ordering links', () {
    final result = NearbyFoodParser.parse({
      'status': 'success',
      'message': 'Tempat makan sekitar berhasil ditemukan.',
      'places': [
        {
          'id': 'place-1',
          'name': 'Warung Sehat',
          'address': 'Jalan Contoh 1',
          'mapsUri': 'https://maps.google.com/?cid=1',
          'websiteUri': 'https://warung.example/menu',
          'rating': 4.5,
          'userRatingCount': 120,
          'priceLevel': 'PRICE_LEVEL_MODERATE',
          'openNow': true,
          'delivery': true,
          'takeout': true,
          'dineIn': false,
        },
      ],
    });

    expect(result.places.single.name, 'Warung Sehat');
    expect(result.places.single.delivery, isTrue);
    expect(result.places.single.mapsUri, startsWith('https://'));
  });

  test('rejects executable or non-HTTPS place links', () {
    final result = NearbyFoodParser.parse({
      'status': 'success',
      'message': 'Tempat ditemukan.',
      'places': [
        {
          'id': 'place-1',
          'name': 'Tempat Tidak Aman',
          'address': '',
          'mapsUri': 'javascript:alert(1)',
          'websiteUri': '',
          'rating': null,
          'userRatingCount': 0,
          'priceLevel': '',
          'openNow': null,
          'delivery': false,
          'takeout': false,
          'dineIn': false,
        },
      ],
    });

    expect(result.places, isEmpty);
  });
}
