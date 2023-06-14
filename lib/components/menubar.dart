import 'package:flutter/material.dart';

class MenuItem {
  const MenuItem({
    required this.title,
    this.keybind,
    required this.onPressed,
  });

  final String title;
  final MenuSerializableShortcut? keybind;
  final VoidCallback onPressed;
}

class SubMenuItem {
  const SubMenuItem({
    required this.title,
    required this.items,
  });

  final String title;
  final List<MenuItem> items;
}

class MyMenuBar extends StatefulWidget {
  final List<SubMenuItem> menuItems;
  const MyMenuBar({super.key, required this.menuItems});

  @override
  State<StatefulWidget> createState() => _MyMenuBarState();
}

// state of the menu bar
class _MyMenuBarState extends State<MyMenuBar> {
  ShortcutRegistryEntry? _shortcutsEntry;

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var menuShape = MaterialStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))));
    var result = PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: MenuBar(
                style: MenuStyle(
                    fixedSize: MaterialStateProperty.all<Size>(
                        const Size.fromHeight(30))),
                children: <Widget>[
                  for (var item in widget.menuItems)
                    SubmenuButton(
                        style: ButtonStyle(shape: menuShape),
                        menuStyle: MenuStyle(shape: menuShape),
                        menuChildren: [
                          for (var subItem in item.items)
                            MenuItemButton(
                              onPressed: subItem.onPressed,
                              shortcut: subItem.keybind,
                              child: Text(subItem.title),
                            ),
                        ],
                        child: Text(item.title)),
                ],
              ),
            ),
          ],
        ));

    if (_shortcutsEntry == null) {
      Map<ShortcutActivator, Intent> shortcuts = {};
      for (var item in widget.menuItems) {
        for (var subItem in item.items) {
          if (subItem.keybind != null) {
            shortcuts[subItem.keybind!] = VoidCallbackIntent(subItem.onPressed);
          }
        }
      }
      _shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
    }

    return result;
  }
}
