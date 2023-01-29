import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:image/image.dart' as ImageModule;

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

  Future<String> cropAndResizeImage(String base64Image) async {
    // Decode base64 image to Image object
    final image = ImageModule.decodeImage(base64Decode(base64Image))!;

    // Crop image to 64x64 (fit width and center)
    final cropWidth = min(image.width, 64);
    final cropHeight = min(image.height, 64);
    final cropX = (image.width - cropWidth) ~/ 2;
    final cropY = (image.height - cropHeight) ~/ 2;
    final croppedImage = ImageModule.copyCrop(image, x: cropX, y: cropY, width: cropWidth, height: cropHeight);

    // Encode cropped image to base64
    final base64CroppedImage = base64Encode(croppedImage.getBytes());

    developer.log(base64CroppedImage);

    return base64CroppedImage;
  }
}
