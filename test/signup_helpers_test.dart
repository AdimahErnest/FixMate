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
    test('accepts a valid contact and password with eight characters', () {
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
      expect(isValidSignupEmail(' person@example.com '), isTrue);
      expect(isValidSignupEmail('missing-domain'), isFalse);
      expect(isValidSignupCode('123456'), isTrue);
      expect(isValidSignupCode('12345'), isFalse);
    });

    group('signup location validation', () {
      test('accepts a town in its selected region', () {
        expect(
          validateSignupLocation(region: 'Littoral', town: 'Douala'),
          isNull,
        );
        expect(
          validateSignupLocation(region: 'Far North', town: 'Maroua'),
          isNull,
        );
      });

      test('requires a known region and a town belonging to it', () {
        expect(
          validateSignupLocation(region: null, town: null),
          'Please select your region.',
        );
        expect(
          validateSignupLocation(region: 'Littoral', town: 'Yaoundé'),
          'Please select a town in your region.',
        );
        expect(
          validateSignupLocation(region: 'Unknown', town: 'Douala'),
          'Please select your region.',
        );
      });
    });

    test('requires eight characters and matching passwords', () {
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
      expect(isStrongSignupPassword('Customers1'), isTrue);
      expect(validateSignupPassword(
        password: 'password',
        confirmPassword: 'Customers1',
      ), 'Passwords do not match.');
      expect(isStrongSignupPassword('lowercase'), isTrue);
      expect(isStrongSignupPassword('12345678'), isTrue);
      expect(isStrongSignupPassword('Abcdefgh'), isTrue);
      expect(isStrongSignupPassword('1234567'), isFalse);
      expect(validateSignupPassword(
        password: 'password',
        confirmPassword: 'password',
      ), isNull);
    });
  });

  group('password recovery code validation', () {
    test('accepts numeric six-to-eight digit email codes', () {
      expect(isValidRecoveryCode('123456'), isTrue);
      expect(isValidRecoveryCode('12345678'), isTrue);
    });

    test('rejects short, long, or non-numeric codes', () {
      expect(isValidRecoveryCode('12345'), isFalse);
      expect(isValidRecoveryCode('123456789'), isFalse);
      expect(isValidRecoveryCode('12ab56'), isFalse);
    });
  });
}
