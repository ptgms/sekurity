import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:sekurity/tools/otp-migration.pb.dart';

final _algorithm = {
  0: "unspecified",
  1: "sha1",
  2: "sha256",
  3: "sha512",
  4: "md5",
};

final _digitCount = {
  0: "unspecified",
  1: 6,
  2: 8,
};

final _otpType = {
  0: "unspecified",
  1: "hotp",
  2: "totp",
};

Future<List<Map<String, dynamic>>> parseMigrationURL(String sourceUrl) async {
  var uri = Uri.parse(sourceUrl);
  var sourceData = uri.queryParameters['data'];

  if (sourceData == null) {
    throw new Exception("source url doesn't contain otpauth data");
  }

  var migrationPayload = MigrationPayload.fromBuffer(base64.decode(sourceData));

  var otpParameters = <Map<String, dynamic>>[];
  for (var otpParameter in migrationPayload.otpParameters) {
    otpParameters.add({
      'secret': base32.encode(Uint8List.fromList(otpParameter.secret)),
      'name': otpParameter.name,
      'issuer': otpParameter.issuer,
      'algorithm': _algorithm[otpParameter.algorithm],
      'digits': _digitCount[otpParameter.digits],
      'type': _otpType[otpParameter.type],
      'counter': otpParameter.counter,
    });
  }

  return otpParameters;
}
