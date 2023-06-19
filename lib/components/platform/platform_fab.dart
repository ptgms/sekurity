import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:fluent_ui/fluent_ui.dart' as fui;

class PlatformFloatingActionButton extends StatefulWidget {
  const PlatformFloatingActionButton(
      {super.key, required this.icon, this.mini, required this.onPressed, this.tooltip});
  final Widget icon;
  final bool? mini;
  final Function onPressed;
  final bool destructive = false;
  final String? tooltip;

  @override
  State<PlatformFloatingActionButton> createState() => _PlatformFloatingActionButtonState();
}

class _PlatformFloatingActionButtonState extends State<PlatformFloatingActionButton> {
  @override
  Widget build(BuildContext context) {
    switch (getPlatform()) {
      case Platforms.macos:
      case Platforms.ios:
        return Tooltip(message: widget.tooltip, child: CupertinoButton(
          onPressed: () => widget.onPressed.call(),
          child: widget.icon,
        ));
      case Platforms.windows:
        return fui.Button(
          onPressed: () => widget.onPressed.call(),
          child: widget.icon,
        );
      default:
        return FloatingActionButton(
            onPressed: () => widget.onPressed.call(), mini: widget.mini??false, tooltip: widget.tooltip, child: widget.icon);
    }
  }
}
