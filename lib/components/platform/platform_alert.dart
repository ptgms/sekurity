import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:sekurity/tools/platformtools.dart';

class PlatformAlertButtons {
  String text = "";
  Function onPressed;
  bool destructive = false;

  PlatformAlertButtons(
      {required this.text, required this.onPressed, this.destructive = false});
}

void showPlatformDialog(BuildContext context,
    {required Widget title,
    Widget? content,
    required List<PlatformAlertButtons> buttons}) {
  switch (getPlatform()) {
    case Platforms.ios:
    case Platforms.macos:
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: title,
          content: content,
          actions: buttons
              .map((e) => CupertinoDialogAction(
                    onPressed: () => e.onPressed.call(),
                    isDestructiveAction: e.destructive,
                    child: Text(e.text),
                  ))
              .toList(),
        ),
      );
      break;
    case Platforms.web:
    case Platforms.linux:
    case Platforms.android:
    default:
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: title,
          content: content,
          actions: buttons
              .map((e) => TextButton(
                    onPressed: () => e.onPressed.call(),
                    style: TextButton.styleFrom(
                        foregroundColor: e.destructive ? Colors.red : null),
                    child: Text(e.text),
                  ))
              .toList(),
        ),
      );
      break;
  }
}
