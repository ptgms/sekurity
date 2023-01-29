import 'dart:math';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import 'package:sekurity/tools/keymanagement.dart';

class CodeManagement {
  static String generateCode(KeyStruct key) {
    // Generate 2FA code based on string key.key TOTP
    var keyBytes = base32.decode(key.key);
    var time = DateTime.now().millisecondsSinceEpoch;
    var timeBytes = List<int>.empty(growable: true);

    // Convert time to bytes
    for (var i = 0; i < 8; i++) {
      timeBytes.add((time >> (i * 8)) & 0xff);
    }
    timeBytes = timeBytes.reversed.toList();

    // Hash time bytes with key bytes
    var hmacSha1 = Hmac(sha1, keyBytes);
    var hmacSha1Bytes = hmacSha1.convert(timeBytes).bytes;

    // Get offset
    var offset = hmacSha1Bytes.last & 0xf;

    // Get code
    var code = ((hmacSha1Bytes[offset] & 0x7f) << 24) |
        ((hmacSha1Bytes[offset + 1] & 0xff) << 16) |
        ((hmacSha1Bytes[offset + 2] & 0xff) << 8) |
        (hmacSha1Bytes[offset + 3] & 0xff);

    // Return code
    return (code % pow(10, 6)).toString().padLeft(6, "0");
  }
}
