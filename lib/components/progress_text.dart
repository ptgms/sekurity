import 'dart:ui';

import 'package:flutter/material.dart';

class ProgressbarText extends StatelessWidget {
  final String text;
  final double progress;
  final Color color;

  const ProgressbarText({super.key, required this.text, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
      colors: [color, color.withOpacity(0.5)],
      stops: [progress, progress],
    );

    Widget gradientText = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );

    // anti-aliasing the text
    Widget antiAliasedText = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: gradientText,
      ),
    );

    return antiAliasedText;
  }
}