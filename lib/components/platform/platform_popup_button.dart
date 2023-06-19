import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:sekurity/tools/platformtools.dart';

class PlatformButton {
  String text = "";
  Function onPressed;
  bool destructive = false;

  PlatformButton({required this.text, required this.onPressed, this.destructive = false});
}

/// Returns a platform specific popup menu button
class PlatformPopupMenuButton extends StatefulWidget {
  const PlatformPopupMenuButton({super.key, required this.items});
  final List<PlatformButton> items;

  @override
  State<PlatformPopupMenuButton> createState() =>
      _PlatformPopupMenuButtonState();
}

class _PlatformPopupMenuButtonState extends State<PlatformPopupMenuButton> {
  @override
  Widget build(BuildContext context) {
    Platforms platform = getPlatform();
    switch (platform) {
      case Platforms.macos:
      case Platforms.ios:
        return PullDownButton(
            itemBuilder: (context) => widget.items
                .map((e) => PullDownMenuItem(
                    title: e.text, onTap: () => e.onPressed.call()))
                .toList(),
            buttonBuilder: (context, showMenu) => CupertinoButton(
                  onPressed: showMenu,
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.ellipsis_circle),
                ));
      case Platforms.linux:
      case Platforms.web:
      case Platforms.android:
      default:
        return PopupMenuButton(
          itemBuilder: (BuildContext context) {
            return widget.items.map((PlatformButton choice) {
              return PopupMenuItem(
                value: choice,
                child: Text(choice.text),
              );
            }).toList();
          },
          onSelected: (value) {
            value.onPressed.call();
          },
        );
    }
  }
}
