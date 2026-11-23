import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// RFC 6238 Time-Based One-Time Password (TOTP) Service
/// Compatible with Google Authenticator, Microsoft Authenticator, and standard RFC 6238 apps.
class TotpService {
  static const String _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// Generates a random Base32 secret string (16 or 20 characters)
  static String generateSecret({int length = 20}) {
    final rand = Random.secure();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_base32Chars[rand.nextInt(_base32Chars.length)]);
    }
    return buffer.toString();
  }

  /// Formats a base32 secret into 4-character separated groups for human entry (e.g. ABCD EFGH IJKL)
  static String formatSecret(String secret) {
    final clean = secret.replaceAll(' ', '').toUpperCase();
    final chunks = <String>[];
    for (int i = 0; i < clean.length; i += 4) {
      final end = (i + 4 <= clean.length) ? i + 4 : clean.length;
      chunks.add(clean.substring(i, end));
    }
    return chunks.join(' ');
  }

  /// Builds the standard `otpauth://totp/...` URI for Google Authenticator QR/Key import
  static String generateOtpAuthUri({
    required String email,
    required String secret,
    String issuer = 'CricPavilion',
  }) {
    final cleanSecret = secret.replaceAll(' ', '').toUpperCase();
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedLabel = Uri.encodeComponent('$issuer:$email');
    return 'otpauth://totp/$encodedLabel?secret=$cleanSecret&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }

  /// Decodes an RFC 4648 Base32 string into raw bytes
  static Uint8List base32Decode(String input) {
    final clean = input.replaceAll(' ', '').replaceAll('=', '').toUpperCase();
    final bits = StringBuffer();

    for (int i = 0; i < clean.length; i++) {
      final val = _base32Chars.indexOf(clean[i]);
      if (val == -1) continue;
      bits.write(val.toRadixString(2).padLeft(5, '0'));
    }

    final bitStr = bits.toString();
    final byteCount = bitStr.length ~/ 8;
    final result = Uint8List(byteCount);

    for (int i = 0; i < byteCount; i++) {
      final byteStr = bitStr.substring(i * 8, (i + 1) * 8);
      result[i] = int.parse(byteStr, radix: 2);
    }

    return result;
  }

  /// Calculates the 6-digit TOTP code for a given secret at a specific [time]
  static String generateTotpCode({
    required String secret,
    DateTime? time,
    int stepSeconds = 30,
    int digits = 6,
  }) {
    final t = time ?? DateTime.now();
    final timeStep = (t.millisecondsSinceEpoch ~/ 1000) ~/ stepSeconds;

    // Convert timeStep to 8-byte big-endian buffer
    final timeBytes = Uint8List(8);
    var tempStep = timeStep;
    for (int i = 7; i >= 0; i--) {
      timeBytes[i] = tempStep & 0xFF;
      tempStep = tempStep >> 8;
    }

    final keyBytes = base32Decode(secret);
    if (keyBytes.isEmpty) return '000000';

    final hmac = Hmac(sha1, keyBytes);
    final hash = hmac.convert(timeBytes).bytes;

    // Dynamic truncation per RFC 4226 / RFC 6238
    final offset = hash[hash.length - 1] & 0x0F;
    final binaryCode = ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    final modulo = pow(10, digits).toInt();
    final otp = binaryCode % modulo;
    return otp.toString().padLeft(digits, '0');
  }

  /// Verifies a 6-digit TOTP code against a secret with a $\pm [window]$ time tolerance
  /// Default window = 1 allows 30 seconds before, current, and 30 seconds after (90s total)
  static bool verifyTotpCode({
    required String secret,
    required String code,
    DateTime? time,
    int window = 1,
  }) {
    final cleanCode = code.replaceAll(' ', '').trim();
    if (cleanCode.length != 6) return false;

    final baseTime = time ?? DateTime.now();

    for (int i = -window; i <= window; i++) {
      final checkTime = baseTime.add(Duration(seconds: i * 30));
      final generated = generateTotpCode(secret: secret, time: checkTime);
      if (generated == cleanCode) {
        return true;
      }
    }
    return false;
  }

  /// Generates human-friendly 8-character recovery backup codes (e.g. "8734-9210")
  static List<String> generateRecoveryCodes({int count = 6}) {
    final rand = Random.secure();
    final codes = <String>[];
    for (int i = 0; i < count; i++) {
      final part1 = (rand.nextInt(9000) + 1000).toString();
      final part2 = (rand.nextInt(9000) + 1000).toString();
      codes.add('$part1-$part2');
    }
    return codes;
  }
}
