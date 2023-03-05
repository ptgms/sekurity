import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_module;

class StructTools {
  Color getTextColor(Color backgroundColor) {
    double darkness = 1 - (0.299 * backgroundColor.red + 0.587 * backgroundColor.green + 0.114 * backgroundColor.blue) / 255;
    if (darkness < 0.5) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  Color randomColorGenerator() {
    return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  String cropAndResizeImage(String base64Image) {
    // Decode the base64 image into bytes
    Uint8List bytes = base64.decode(base64Image);

    // Decode the image bytes into an Image object using the image package
    image_module.Image? image = image_module.decodeImage(bytes);

    // Calculate the crop dimensions while preserving aspect ratio
    int width = image!.width;
    int height = image.height;
    double ratio = width / height;
    int cropSize = ratio >= 1 ? height : width;
    int x = (width - cropSize) ~/ 2;
    int y = (height - cropSize) ~/ 2;

    // Crop the image to 64x64 using the Image package
    image_module.Image croppedImage = image_module.copyCrop(image, x: x, y: y, width: width, height: height);

    // Resize the cropped image to 64x64 using the Image package
    image_module.Image resizedImage = image_module.copyResize(croppedImage, width: 64, height: 64);

    // Encode the resized image into base64
    Uint8List resizedBytes = image_module.encodePng(resizedImage);
    String resizedBase64 = base64.encode(resizedBytes);

    // Return the base64 encoded image
    return resizedBase64;
  }
}
