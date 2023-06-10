import 'dart:async';

import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/otp-migration.pbenum.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:base32/base32.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'dart:developer' as developer;

import 'decode_migration.dart';
import 'encryption_tools.dart';

class KeyStruct {
  String iconBase64;
  String key; // <- This is the reason we use encrypted storage
  String service;
  String description;
  Color color;
  bool eightDigits;
  OTPAlgorithm algorithm;
  int interval;
  KeyStruct(
      {required this.iconBase64,
      required this.key,
      required this.service,
      required this.description,
      required this.color,
      this.eightDigits = false,
      this.algorithm = OTPAlgorithm.SHA1,
      this.interval = 30});
}

class KeyManagement {
  final _storage = const FlutterSecureStorage();

  bool isValidBase32(String input) {
    RegExp base32RegExp = RegExp(r'^[A-Z2-7]+$');
    if (!base32RegExp.hasMatch(input)) {
      return false;
    }
    try {
      base32.decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> getSavedKeys(context) async {
    final itemModel = Provider.of<Keys>(context, listen: false);
    var keys = await _storage.read(key: "keys");
    //developer.log(keys != null ? "Found keys!" : "null");
    if (keys == null) {
      return false;
    }

    // keys is a json string that has to be parsed into List<KeyStruct>
    var jsonKeys = jsonDecode(keys);
    for (var key in jsonKeys) {
      // Check if secret key is valid base32 string
      if (!isValidBase32(key["key"])) {
        continue;
      }
      itemModel.addItem(KeyStruct(
          iconBase64: key["iconBase64"],
          key: key["key"],
          service: key["service"],
          color: Color(key["color"]),
          description: key["description"] ?? "",
          eightDigits: key["eightDigits"] ?? false,
          algorithm: key["algorithm"] == "SHA1"
              ? OTPAlgorithm.SHA1
              : key["algorithm"] == "SHA256"
                  ? OTPAlgorithm.SHA256
                  : key["algorithm"] == "SHA512"
                      ? OTPAlgorithm.SHA512
                      : OTPAlgorithm.SHA1,
          interval: key["interval"] ?? 30));
    }
    return true;
  }

  Future<bool> migrateData(String key, context) async {
    final itemModel = Provider.of<Keys>(context, listen: false);
    developer.log("Migrating!");
    var decodedData = await parseMigrationURL(key);

    for (var key in decodedData) {
      // Check if key is already saved
      if (itemModel.items.any((element) => element.key == key["secret"])) {
        continue;
      }

      if (!isValidBase32(key["secret"])) {
        continue;
      }

      var serviceName = key["name"];
      developer.log("Found service: $serviceName");
      var serviceNameSplitted = serviceName.split(":");
      serviceName = serviceNameSplitted[0];
      if (serviceNameSplitted.length > 1) {}
      var secret = key["secret"];

      var eightDigits = key["digits"] == MigrationPayload_DigitCount.DIGIT_COUNT_EIGHT;

      var algorithm = key["algorithm"] == MigrationPayload_Algorithm.ALGORITHM_SHA1
          ? OTPAlgorithm.SHA1
          : key["algorithm"] == MigrationPayload_Algorithm.ALGORITHM_SHA256
              ? OTPAlgorithm.SHA256
              : key["algorithm"] == MigrationPayload_Algorithm.ALGORITHM_SHA512
                  ? OTPAlgorithm.SHA512
                  : OTPAlgorithm.SHA1;

      var color = Colors.white;
      var icon = "";

      // Get default color and icon from json
      final defaultServices = await rootBundle.loadString('assets/services.json');
      // Structure: { "discord": { "color": "#7289DA", "icon": "discord" }, ... }
      final Map<String, dynamic> defaultServicesMap = jsonDecode(defaultServices);
      if (defaultServicesMap.containsKey(serviceName.toLowerCase())) {
        color = Color(defaultServicesMap[serviceName.toLowerCase()]["color"]);
        icon = defaultServicesMap[serviceName.toLowerCase()]["icon"];
      } else {
        // Random color
        color = StructTools().randomColorGenerator();
      }

      var keyStruct =
          KeyStruct(iconBase64: icon, key: secret, service: serviceName, description: "", color: color, eightDigits: eightDigits, algorithm: algorithm);
      await addKeyManual(keyStruct, context);
    }
    return true;
  }

  // Same as migrateData but to encode a QR code
  Future<QrImageView > parseTransferQR(context) async {
    final itemModel = Provider.of<Keys>(context, listen: false);
    developer.log("Transfering!");
    var encodedKeys = await parseTransferURL(itemModel.items);
    var url = "otpauth-migration://offline?$encodedKeys";

    // generate QR code from url
    var qr = QrImageView(
      backgroundColor: Colors.white,
      data: url,
      version: QrVersions.auto,
      size: 200.0,
    );
    return qr;
  }

  Future<bool> addURL(String key, context) async {
    final itemM = Provider.of<Keys>(context, listen: false);
    // Read OTP link null-safely using Uri
    var uri = Uri.parse(key);
    var serviceName = Uri.decodeFull(uri.pathSegments[0]);
    // The part after the colon is the description, if it exists
    var serviceNameSplitted = serviceName.split(":");
    serviceName = serviceNameSplitted[0];
    var description = "";
    if (serviceNameSplitted.length > 1) {
      description = serviceNameSplitted[1];
    }
    var secret = uri.queryParameters["secret"] ?? "";

    var digits = uri.queryParameters["digits"] ?? "6";

    var algorithmJson = uri.queryParameters["algorithm"] ?? "SHA1";
    var algorithm = algorithmJson == "SHA1"
        ? OTPAlgorithm.SHA1
        : algorithmJson == "SHA256"
            ? OTPAlgorithm.SHA256
            : algorithmJson == "SHA512"
                ? OTPAlgorithm.SHA512
                : OTPAlgorithm.SHA1;

    var interval = uri.queryParameters["period"] ?? "30";

    // Check if key is already saved
    if (itemM.items.any((element) => element.key == secret)) {
      return false;
    }

    if (!isValidBase32(secret)) {
      return false;
    }

    // Get default color and icon from json
    final defaultServices = await rootBundle.loadString('assets/services.json');
    // Structure: { "discord": { "color": 4283983346, "icon": "base64"} }

    var color = StructTools().randomColorGenerator();
    var icon = "";

    if (jsonDecode(defaultServices).containsKey(serviceName.toLowerCase())) {
      // Get color and icon from json
      color = Color(jsonDecode(defaultServices)[serviceName.toLowerCase()]["color"]);
      icon = jsonDecode(defaultServices)[serviceName.toLowerCase()]["icon"];
    }

    // Add key to list
    itemM.addItem(KeyStruct(
        iconBase64: icon,
        key: secret,
        service: serviceName,
        description: description,
        eightDigits: digits == "8",
        color: color,
        algorithm: algorithm,
        interval: int.parse(interval)));

    return await saveKeys(itemM.items);
  }

  Future<bool> addKeyQR(String key, context) async {
    // OTP link format: otpauth://totp/ServiceName:DescriptionText?secret=SECRET
    // Or: otpauth://totp/ServiceName?secret=SECRET
    // Description is optional

    // Check if migration QR code is used
    developer.log("QR Code scanned!");
    if (key.startsWith("otpauth-migration://offline?")) {
      return await migrateData(key, context);
    }

    return addURL(key, context);
  }

  Future<bool> deleteKey(KeyStruct keyStruct, context) async {
    final itemModel = Provider.of<Keys>(context, listen: false);
    itemModel.removeItem(keyStruct);
    return await saveKeys(itemModel.items);
  }

  Future<bool> addKeyManual(KeyStruct keyStruct, context) async {
    final itemModel = Provider.of<Keys>(context, listen: false);

    // Check if key is already saved
    if (itemModel.items.any((element) => element.key == keyStruct.key)) {
      return false;
    }

    if (!isValidBase32(keyStruct.key)) {
      return false;
    }

    itemModel.addItem(keyStruct);
    return await saveKeys(itemModel.items);
  }

  Future<bool> saveKeys(List<KeyStruct> keys) async {
    //version.value++;
    // Parse List<KeyStruct> into json string
    var jsonKeys = List<Map<String, dynamic>>.empty(growable: true);
    for (var key in keys) {
      jsonKeys.add({
        "iconBase64": key.iconBase64,
        "key": key.key,
        "service": key.service,
        "color": key.color.value,
        "description": key.description,
        "eightDigits": key.eightDigits,
        "algorithm": key.algorithm == OTPAlgorithm.SHA1
            ? "SHA1"
            : key.algorithm == OTPAlgorithm.SHA256
                ? "SHA256"
                : key.algorithm == OTPAlgorithm.SHA512
                    ? "SHA512"
                    : "SHA1",
        "interval": key.interval
      });
    }
    var jsonKeysString = jsonEncode(jsonKeys);
    //developer.log(jsonKeysString);
    // Save json string into FlutterSecureStorage
    await _storage.write(key: "keys", value: jsonKeysString);
    return true;
  }

  Future<bool> getEncryptedJson(String password, context) async {
    final itemModel = Provider.of<Keys>(context, listen: false);
    var jsonKeys = List<Map<String, dynamic>>.empty(growable: true);
    for (var key in itemModel.items) {
      jsonKeys.add({
        "iconBase64": key.iconBase64,
        "key": key.key,
        "service": key.service,
        "color": key.color.value,
        "description": key.description,
        "eightDigits": key.eightDigits,
        "algorithm": key.algorithm == OTPAlgorithm.SHA1
            ? "SHA1"
            : key.algorithm == OTPAlgorithm.SHA256
                ? "SHA256"
                : key.algorithm == OTPAlgorithm.SHA512
                    ? "SHA512"
                    : "SHA1",
        "interval": key.interval
      });
    }
    var jsonKeysString = jsonEncode(jsonKeys);

    developer.log(jsonKeysString);

    var encrypted = await encryptJson(jsonKeysString, password);

    if (encrypted == null) {
      return false;
    }

    if (isPlatformWeb()) {
      var blob = html.Blob([encrypted]);
      var url = html.Url.createObjectUrlFromBlob(blob);
      var anchor = html.AnchorElement(href: url);
      anchor.download = "otp_backup.keys";
      anchor.click();
    } else {
      if (isPlatformMobile()) {
        // Open file save dialog with the bytes encrypted
        var filePath = await FilePicker.platform.getDirectoryPath(dialogTitle: "Select directory to save");

        if (filePath == null) {
          return false;
        }

        var file = io.File("$filePath/otp_backup.keys");
        await file.writeAsBytes(encrypted);
      } else {
        // Open file save dialog with the bytes encrypted
        var filePath = await FilePicker.platform
            .saveFile(dialogTitle: "Save encrypted file", fileName: "otp_backup.keys", type: FileType.custom, allowedExtensions: ["keys"]);

        if (filePath == null) {
          return false;
        }
        var file = io.File(filePath);
        await file.writeAsBytes(encrypted);
      }
    }

    return true;
  }

  Future<bool> getDecryptedJson(String password) async {
    // On mobile filetypes are not supported
    FilePickerResult? filePath;
    if (isPlatformMobile()) {
      filePath = await FilePicker.platform.pickFiles(dialogTitle: "Select encrypted file");
    } else {
      filePath = await FilePicker.platform.pickFiles(dialogTitle: "Select encrypted file", type: FileType.custom, allowedExtensions: ["keys"]);
    }

    if (filePath == null) {
      return false;
    }

    var file = io.File(filePath.files.first.path!);

    var encrypted = await file.readAsBytes();

    var decrypted = await decryptJson(encrypted, password);

    if (decrypted == "") {
      return false;
    }

    var jsonKeys = jsonDecode(decrypted);

    var keys = List<KeyStruct>.empty(growable: true);

    for (var key in jsonKeys) {
      keys.add(KeyStruct(
          iconBase64: key["iconBase64"],
          key: key["key"],
          service: key["service"],
          color: Color(key["color"]),
          description: key["description"],
          eightDigits: key["eightDigits"],
          algorithm: key["algorithm"] == "SHA1"
              ? OTPAlgorithm.SHA1
              : key["algorithm"] == "SHA256"
                  ? OTPAlgorithm.SHA256
                  : key["algorithm"] == "SHA512"
                      ? OTPAlgorithm.SHA512
                      : OTPAlgorithm.SHA1,
          interval: key["interval"]));
    }

    return await saveKeys(keys);
  }
}
