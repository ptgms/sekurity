import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:sekurity/tools/platformtools.dart';

class PlatformTextButton extends StatefulWidget {
  const PlatformTextButton({super.key, required this.text, required this.onPressed});
  final String text;
  final Function onPressed;
  final bool destructive = false;
  
  @override
  State<PlatformTextButton> createState() => _PlatformTextButtonState();
}

class _PlatformTextButtonState extends State<PlatformTextButton> {
  @override
  Widget build(BuildContext context) {
    switch (getPlatform()) {
      case Platforms.macos:
      case Platforms.ios:
        return CupertinoButton(
          onPressed: () => widget.onPressed.call(),
          child: Text(widget.text, style: TextStyle(color: widget.destructive ? CupertinoColors.destructiveRed : null)),
        );
      default:
        return TextButton(
          onPressed: () => widget.onPressed.call(),
          child: Text(widget.text, style: TextStyle(color: widget.destructive ? Colors.red : null))
        );
    }
  }
}