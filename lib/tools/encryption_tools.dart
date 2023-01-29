import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:developer' as developer;

Future<Uint8List?> encryptJson(String json, String password) async {
  try {
    // We will hash the password to get a 256 bit key
    var keyHash = sha256.convert(utf8.encode(password)).bytes;

    final key = Key.fromBase64(base64.encode(keyHash));
    final iv = IV.fromLength(16);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(json, iv: iv);

    return encrypted.bytes;
  } catch (e) {
    developer.log(e.toString());
    return null;
  }
}

Future<String> decryptJson(Uint8List encrypted, String password) async {
  try {
    // We will hash the password to get a 256 bit key
    var keyHash = sha256.convert(utf8.encode(password)).bytes;

    final key = Key.fromBase64(base64.encode(keyHash));
    final iv = IV.fromLength(16);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final decrypted = encrypter.decrypt(Encrypted(encrypted), iv: iv);

    return decrypted;
  } catch (e) {
    developer.log(e.toString());
    return "";
  }
}
