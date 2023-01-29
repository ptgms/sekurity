import 'dart:async';

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
  KeyStruct({required this.iconBase64, required this.key, required this.service, required this.description, required this.color});
}

class KeyManagement {
  final _storage = const FlutterSecureStorage();

  ValueNotifier<int> version = ValueNotifier(0);

  bool isValidBase32(String input) {
    RegExp base32RegExp = RegExp(r'^[A-Z2-7]+$');
    if (!base32RegExp.hasMatch(input)) {
      return false;
    }
    try {
      var bytes = base32.decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<KeyStruct>> getSavedKeys() async {
    var keys = await _storage.read(key: "keys");
    developer.log(keys != null ? "Found keys!" : "null");
    if (keys == null) {
      return List<KeyStruct>.empty(growable: true);
    }

    // keys is a json string that has to be parsed into List<KeyStruct>
    var keyList = List<KeyStruct>.empty(growable: true);
    var jsonKeys = jsonDecode(keys);
    for (var key in jsonKeys) {
      // Check if secret key is valid base32 string
      if (!isValidBase32(key["key"])) {
        continue;
      }
      keyList.add(KeyStruct(
          iconBase64: key["iconBase64"], key: key["key"], service: key["service"], color: Color(key["color"]), description: key["description"] ?? ""));
    }
    return keyList;
  }

  Future<bool> migrateData(String key) async {
    developer.log("Migrating!");
    var decodedData = await parseMigrationURL(key);
    var keys = await getSavedKeys();

    for (var key in decodedData) {
      // Check if key is already saved
      if (keys.any((element) => element.key == key["secret"])) {
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
        color = Color((0xFF000000 + (0xFFFFFF * (0.5 + (0.5 * (serviceName.hashCode / 0xFFFFFFFF))))).toInt());
      }

      var keyStruct = KeyStruct(iconBase64: icon, key: secret, service: serviceName, description: "", color: color);
      await addKeyManual(keyStruct);
    }
    return true;
  }

  Future<bool> addURL(String key) async {
    var keys = await getSavedKeys();
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

    // Check if key is already saved
    if (keys.any((element) => element.key == secret)) {
      return false;
    }

    if (!isValidBase32(secret)) {
      return false;
    }

    // Get default color and icon from json
    final defaultServices = await rootBundle.loadString('assets/services.json');
    // Structure: { "discord": { "color": 4283983346, "icon": "base64"} }

    var color = Colors.white;
    var icon = "";

    if (jsonDecode(defaultServices).containsKey(serviceName.toLowerCase())) {
      // Get color and icon from json
      color = Color(jsonDecode(defaultServices)[serviceName.toLowerCase()]["color"]);
      icon = jsonDecode(defaultServices)[serviceName.toLowerCase()]["icon"];
    }

    // Add key to list
    keys.add(KeyStruct(iconBase64: icon, key: secret, service: serviceName, description: description, color: color));

    return await saveKeys(keys);
  }

  Future<bool> addKeyQR(String key) async {
    // OTP link format: otpauth://totp/ServiceName:DescriptionText?secret=SECRET
    // Or: otpauth://totp/ServiceName?secret=SECRET
    // Description is optional

    // Check if migration QR code is used
    developer.log("QR Code scanned!");
    if (key.startsWith("otpauth-migration://offline?")) {
      return await migrateData(key);
    }

    return addURL(key);
  }

  Future<bool> deleteKey(KeyStruct keyStruct) async {
    var keys = await getSavedKeys();
    keys.remove(keyStruct);
    return await saveKeys(keys);
  }

  Future<bool> addKeyManual(KeyStruct keyStruct) async {
    var keys = await getSavedKeys();

    // Check if key is already saved
    if (keys.any((element) => element.key == keyStruct.key)) {
      return false;
    }

    if (!isValidBase32(keyStruct.key)) {
      return false;
    }

    keys.add(keyStruct);
    return await saveKeys(keys);
  }

  Future<bool> saveKeys(List<KeyStruct> keys) async {
    version.value++;
    // Parse List<KeyStruct> into json string
    var jsonKeys = List<Map<String, dynamic>>.empty(growable: true);
    for (var key in keys) {
      jsonKeys.add({"iconBase64": key.iconBase64, "key": key.key, "service": key.service, "color": key.color.value, "description": key.description});
    }
    var jsonKeysString = jsonEncode(jsonKeys);
    //developer.log(jsonKeysString);
    // Save json string into FlutterSecureStorage
    await _storage.write(key: "keys", value: jsonKeysString);
    return true;
  }

  Future<bool> getEncryptedJson(String password) async {
    var keys = await getSavedKeys();
    var jsonKeys = List<Map<String, dynamic>>.empty(growable: true);
    for (var key in keys) {
      jsonKeys.add({"iconBase64": key.iconBase64, "key": key.key, "service": key.service, "color": key.color.value, "description": key.description});
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
      // Open file save dialog with the bytes encrypted
      var filePath = await FilePicker.platform
          .saveFile(dialogTitle: "Save encrypted file", fileName: "otp_backup.keys", type: FileType.custom, allowedExtensions: ["keys"]);

      if (filePath == null) {
        return false;
      }
      var file = io.File(filePath);
      await file.writeAsBytes(encrypted);
    }

    return true;
  }

  Future<bool> getDecryptedJson(String password) async {
    var filePath = await FilePicker.platform.pickFiles(dialogTitle: "Select encrypted file", type: FileType.custom, allowedExtensions: ["keys"]);

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
      keys.add(KeyStruct(iconBase64: key["iconBase64"], key: key["key"], service: key["service"], color: Color(key["color"]), description: key["description"]));
    }

    return await saveKeys(keys);
  }
}
