import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:fluent_ui/fluent_ui.dart' as fui;

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
    case Platforms.windows:
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
    case Platforms.macos:
      fui.showDialog(context: context, builder: (context) => fui.ContentDialog(
        title: title,
        content: content,
        actions: buttons
            .map((e) => e.destructive? fui.FilledButton(
                  onPressed: () => e.onPressed.call(),
                  style: fui.ButtonStyle(backgroundColor: fui.ButtonState.all(fui.Colors.red)),
                  child: Text(e.text, style: const TextStyle(color: Colors.white)),
                ) : fui.Button(
                  onPressed: () => e.onPressed.call(),
                  child: Text(e.text),
                ))
            .toList(),
      ));
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
