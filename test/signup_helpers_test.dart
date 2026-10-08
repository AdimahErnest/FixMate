import 'package:flutter_test/flutter_test.dart';
import 'package:fixmate/widgets/signup_helpers.dart';

void main() {
  group('Cameroon signup phone normalization', () {
    test('normalizes supported local and international formats', () {
      expect(normalizeSignupPhone('+237 677 12 34 56'), '677123456');
      expect(normalizeSignupPhone('0677123456'), '677123456');
      expect(normalizeSignupPhone('677123456'), '677123456');
    });

    test('rejects incomplete and unsupported phone numbers', () {
      expect(normalizeSignupPhone('67712345'), isNull);
      expect(normalizeSignupPhone('123456789'), isNull);
    });
  });

  group('signup validation', () {
    test('accepts a valid contact and strong password', () {
      expect(
        validateSignupFields(
          name: 'FixMate customer',
          email: 'customer@example.com',
          phone: '+237 677 12 34 56',
          password: 'FixMate2026',
          confirmPassword: 'FixMate2026',
        ),
        isNull,
      );
    });

    test('rejects weak or mismatched passwords and invalid emails', () {
      expect(
        validateSignupFields(
          name: 'Customer',
          email: 'invalid-email',
          phone: '677123456',
          password: 'weak',
          confirmPassword: 'different',
        ),
        'Please enter a valid email address.',
      );
      expect(isStrongSignupPassword('lowercase1'), isFalse);
      expect(isStrongSignupPassword('Uppercase1'), isTrue);
    });
  });
}
