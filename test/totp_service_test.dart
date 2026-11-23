import 'package:flutter_test/flutter_test.dart';
import 'package:cricket_app/services/totp_service.dart';

void main() {
  group('TotpService RFC 6238 Unit Tests', () {
    test('generateSecret produces valid Base32 secret', () {
      final secret = TotpService.generateSecret(length: 20);
      expect(secret.length, equals(20));
      expect(RegExp(r'^[A-Z2-7]+$').hasMatch(secret), isTrue);

      final formatted = TotpService.formatSecret(secret);
      expect(formatted.split(' ').length, equals(5));
    });

    test('generateOtpAuthUri creates standard Google Authenticator URI', () {
      final uri = TotpService.generateOtpAuthUri(
        email: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
        issuer: 'CricPavilion Pro',
      );

      expect(uri, contains('otpauth://totp/'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=CricPavilion%20Pro'));
      expect(uri, contains('algorithm=SHA1'));
      expect(uri, contains('digits=6'));
    });

    test('generateTotpCode generates deterministic 6-digit code for timestamp', () {
      final secret = 'JBSWY3DPEHPK3PXP';
      final testTime = DateTime.fromMillisecondsSinceEpoch(1700000000000); // fixed timestamp
      final code1 = TotpService.generateTotpCode(secret: secret, time: testTime);
      final code2 = TotpService.generateTotpCode(secret: secret, time: testTime);

      expect(code1.length, equals(6));
      expect(code1, equals(code2));
      expect(int.tryParse(code1), isNotNull);
    });

    test('verifyTotpCode verifies matching code and rejects invalid code', () {
      final secret = TotpService.generateSecret();
      final now = DateTime.now();
      final validCode = TotpService.generateTotpCode(secret: secret, time: now);

      expect(TotpService.verifyTotpCode(secret: secret, code: validCode, time: now), isTrue);
      expect(TotpService.verifyTotpCode(secret: secret, code: '000000', time: now), isFalse);
      expect(TotpService.verifyTotpCode(secret: secret, code: '12345', time: now), isFalse);
    });

    test('verifyTotpCode respects window drift (30 seconds before and after)', () {
      final secret = TotpService.generateSecret();
      final now = DateTime.now();

      // Code generated 25 seconds ago (within current or immediately preceding step)
      final pastCode = TotpService.generateTotpCode(secret: secret, time: now.subtract(const Duration(seconds: 28)));
      expect(TotpService.verifyTotpCode(secret: secret, code: pastCode, time: now, window: 1), isTrue);

      // Code generated 25 seconds in future (within clock drift window)
      final futureCode = TotpService.generateTotpCode(secret: secret, time: now.add(const Duration(seconds: 28)));
      expect(TotpService.verifyTotpCode(secret: secret, code: futureCode, time: now, window: 1), isTrue);

      // Code generated 120 seconds in future (outside window=1)
      final farFutureCode = TotpService.generateTotpCode(secret: secret, time: now.add(const Duration(seconds: 120)));
      expect(TotpService.verifyTotpCode(secret: secret, code: farFutureCode, time: now, window: 1), isFalse);
    });

    test('generateRecoveryCodes generates 6 unique backup codes', () {
      final codes = TotpService.generateRecoveryCodes(count: 6);
      expect(codes.length, equals(6));
      expect(codes.toSet().length, equals(6));
      for (final code in codes) {
        expect(RegExp(r'^\d{4}-\d{4}$').hasMatch(code), isTrue);
      }
    });
  });
}
