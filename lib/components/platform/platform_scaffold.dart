import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sekurity/components/menubar.dart';
import 'package:sekurity/components/platform/platform_appbar.dart';
import 'package:sekurity/main.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:fluent_ui/fluent_ui.dart' as fui;
import 'package:sekurity/tools/platformtools.dart';

class PlatformScaffold extends StatefulWidget {
  const PlatformScaffold(
      {super.key,
      required this.appBar,
      required this.body,
      this.floatingActionButton});
  final PlatformAppBar appBar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  State<PlatformScaffold> createState() => _PlatformScaffoldState();
}

class _PlatformScaffoldState extends State<PlatformScaffold> {
  // MyMenuBar(menuItems: widget.appBar.menuItems)
  @override
  Widget build(BuildContext context) {
    switch (getPlatform()) {
      case Platforms.macos:
      case Platforms.ios:
        if (isPlatformMobile() ||
            forceAppbar.value ||
            widget.appBar.menuItems == null) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              leading: widget.appBar.leading,
              middle: Text(widget.appBar.title),
              trailing: (isPlatformMobile() || forceAppbar.value)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.appBar.actions ?? [],
                    )
                  : null,
            ),
            child: SafeArea(
                child: Scaffold(
              body: widget.body,
              floatingActionButton: widget.floatingActionButton,
            )),
          );
        } else {
          return Scaffold(
            appBar: PreferredSize(
                preferredSize: const Size.fromHeight(40.0),
                child: MyMenuBar(menuItems: widget.appBar.menuItems ?? [])),
            body: widget.body,
            floatingActionButton: widget.floatingActionButton,
          );
        }
      case Platforms.windows:
        return fui.ScaffoldPage(
            content: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: (isPlatformMobile() || forceAppbar.value)
              ? AppBar(
                  leading: widget.appBar.leading,
                  title: Text(widget.appBar.title),
                  actions: widget.appBar.actions ?? [])
              : PreferredSize(
                  preferredSize: const Size.fromHeight(40.0),
                  child: MyMenuBar(menuItems: widget.appBar.menuItems ?? [])),
          body: widget.body,
          floatingActionButton: widget.floatingActionButton,
        ));
      case Platforms.linux:
      case Platforms.web:
      case Platforms.android:
      default:
        return Scaffold(
          appBar: (isPlatformMobile() || forceAppbar.value)
              ? AppBar(
                  leading: widget.appBar.leading,
                  title: Text(widget.appBar.title),
                  actions: widget.appBar.actions ?? [])
              : PreferredSize(
                  preferredSize: const Size.fromHeight(40.0),
                  child: MyMenuBar(menuItems: widget.appBar.menuItems ?? [])),
          body: widget.body,
          floatingActionButton: widget.floatingActionButton,
        );
    }
  }
}
