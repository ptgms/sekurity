import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:otpauth_migration/otpauth_migration.dart';
import 'dart:developer' as developer;

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

  Future<List<KeyStruct>> getSavedKeys() async {
    var keys = await _storage.read(key: "keys");
    developer.log(keys ?? "null");
    if (keys == null) {
      return List<KeyStruct>.empty(growable: true);
    }

    // keys is a json string that has to be parsed into List<KeyStruct>
    var keyList = List<KeyStruct>.empty(growable: true);
    var jsonKeys = jsonDecode(keys);
    for (var key in jsonKeys) {
      keyList.add(KeyStruct(
          iconBase64: key["iconBase64"], key: key["key"], service: key["service"], color: Color(key["color"]), description: key["description"] ?? ""));
    }
    return keyList;
  }

  Future<bool> migrateData(String key) async {
    developer.log("Migrating!");
    // Example string: otpauth-migration://offline?data=ChwKCkhlbGxvId6tvu8SCFRlc3Qga2V5IAEoATACCh4KCgSGCQwSGAAAAAASClRlc3Qga2V5IDIgASgBMAIQARgBIAAoz8zItwM%3D
    // The data part is base64 encoded
    final otp_auth_parser = OtpAuthMigration();
    final data = otp_auth_parser.decode(key);
    print(key);
    for (String url in data) {
      print(url);
      await addURL(url);
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
    // UnsupportedError (Unsupported operation: Cannot add to a fixed-length list)
    keys.add(keyStruct);
    return await saveKeys(keys);
  }

  Future<bool> saveKeys(List<KeyStruct> keys) async {
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
}
