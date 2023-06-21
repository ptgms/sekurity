import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:sekurity/components/menubar.dart';
import 'package:sekurity/components/platform/platform_appbar.dart';
import 'package:sekurity/components/popup_submenuitem.dart';
import 'package:sekurity/main.dart';
import 'package:sekurity/tools/platforms.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:window_manager/window_manager.dart';

class PlatformScaffold extends StatefulWidget {
  const PlatformScaffold(
      {super.key,
      required this.appBar,
      required this.body,
      this.floatingActionButton,
      this.nonTransparent = false});
  final PlatformAppBar appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool nonTransparent;

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
        if (isPlatformMacos()) {
          Window.setEffect(
            effect: WindowEffect.windowBackground,
            dark: Theme.of(context).brightness == Brightness.dark,
          );
        }
        if (isPlatformMobile() ||
            forceAppbar.value ||
            widget.appBar.menuItems == null) {
          return CupertinoPageScaffold(
            backgroundColor: (isPlatformMacos()&&!widget.nonTransparent)? Colors.transparent : null,
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
            backgroundColor: (isPlatformMacos()&&!widget.nonTransparent)? Colors.transparent : null,
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
        Window.setEffect(
          effect: WindowEffect.mica,
          dark: Theme.of(context).brightness == Brightness.dark,
        );
        return Scaffold(
          backgroundColor: widget.nonTransparent? null : Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Column(
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(50.0),
                  child: Row(
                    children: [
                      if (widget.appBar.leading != null) widget.appBar.leading!,
                      if (widget.appBar.menuItems != null ||
                          (widget.appBar.menuItems??[]).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                          child: PopupMenuButton(
                            tooltip: "",
                            child: const Icon(Icons.menu_rounded),
                            itemBuilder: (_) {
                              return [
                                for (SubMenuItem item in widget.appBar.menuItems ?? [])
                                PopupSubMenuItem(title: item.title, items: [
                                  for (MenuItem subitem in item.items)
                                    PopupMenuItem(
                                      value: subitem,
                                      child: Text(subitem.title),
                                    )
                                ], onSelected: (value) {
                                  value.onPressed.call();
                                })
                              ];
                            },
                          ),
                        ),

                      // weight
                      Expanded(
                        child: DragToMoveArea(
                            child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 20, 3),
                            child: Text(widget.appBar.title),
                          ),
                        )),
                      ),
                      const WindowButtons()
                    ],
                  ),
                )
              ],
            ),
          ),
          body: widget.body,
          floatingActionButton: widget.floatingActionButton,
        );
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

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: Theme.of(context).brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
