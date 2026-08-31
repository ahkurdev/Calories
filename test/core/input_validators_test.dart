import 'package:caloris/core/utils/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators', () {
    test('validates email and password', () {
      expect(InputValidators.email('person@example.com'), isNull);
      expect(InputValidators.email('invalid'), isNotNull);
      expect(InputValidators.password('12345678'), isNull);
      expect(InputValidators.password('short'), isNotNull);
    });

    test('parses Indonesian decimal comma', () {
      expect(InputValidators.parseDecimal('72,5'), 72.5);
    });
  });
}
