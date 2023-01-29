import 'dart:convert';
import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:fixnum/fixnum.dart';
import 'package:sekurity/tools/otp-migration.pb.dart';

import 'keymanagement.dart';

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

Future<String> parseTransferURL(List<KeyStruct> keys) {
  var migrationPayload = MigrationPayload.create();
  migrationPayload.otpParameters.addAll(keys.map((key) {
    var otpParameter = MigrationPayload_OtpParameters.create();
    otpParameter.secret = base32.decode(key.key);
    otpParameter.name = key.service;
    otpParameter.issuer = key.description;
    otpParameter.algorithm = MigrationPayload_Algorithm.ALGORITHM_SHA256;
    otpParameter.digits = key.eightDigits ? MigrationPayload_DigitCount.DIGIT_COUNT_EIGHT : MigrationPayload_DigitCount.DIGIT_COUNT_SIX;
    otpParameter.type = MigrationPayload_OtpType.OTP_TYPE_TOTP;
    otpParameter.counter = Int64(0);
    return otpParameter;
  }));

  return Future.value(base64.encode(migrationPayload.writeToBuffer()));
}
