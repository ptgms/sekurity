import 'dart:convert';

import 'package:context_menus/context_menus.dart';
import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:sekurity/components/animation_push.dart';
import 'package:sekurity/components/menubar.dart';
import 'package:sekurity/components/progress_text.dart';
import 'package:sekurity/homescreen_dialogs.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:system_tray/system_tray.dart';

import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //ValueNotifier<List<double>> progress = ValueNotifier(List<double>.filled(0, 0));
  ValueNotifier<bool> refresher = ValueNotifier(false);

  Future<void> hideWindow() async {
    const storage = FlutterSecureStorage();
    AppWindow().hide();
    storage.write(key: "hidden", value: "true");
  }

  Future<void> showWindow() async {
    const storage = FlutterSecureStorage();
    AppWindow().show();
    storage.write(key: "hidden", value: "false");
  }

  dynamic getShortcut(key, bool extra) {
    if (isPlatformMacos()) {
      return SingleActivator(key, meta: true, includeRepeats: false);
    } else {
      return SingleActivator(key, control: true, includeRepeats: false);
    }
  }

  String generateTOTP(KeyStruct key) {
    // check if setting time is set (time difference between device and server)
    if (time == 0) {
      return TOTP(
              secret: key.key,
              digits: key.eightDigits ? 8 : 6,
              interval: key.interval,
              algorithm: key.algorithm)
          .now();
    } else {
      var timeWithDif = DateTime.now().millisecondsSinceEpoch + time;
      DateTime newTime = DateTime.fromMillisecondsSinceEpoch(timeWithDif);
      return TOTP(
              secret: key.key,
              digits: key.eightDigits ? 8 : 6,
              interval: key.interval,
              algorithm: key.algorithm)
          .value(date: newTime)!;
    }
  }

  Future<void> initSystemTray() async {
    String path =
        isPlatformWindows() ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    // We first init the systray menu
    await systemTray.initSystemTray(
      iconPath: path,
      title: 'Sekurity',
    );

    // ignore: use_build_context_synchronously
    final itemModel = Provider.of<Keys>(context, listen: false);

    // create context menu
    final Menu menu = Menu();
    if (context.mounted) {
      await menu.buildFrom([
        MenuItemLabel(
            label: context.loc.show, onClicked: (menuItem) => showWindow()),
        MenuItemLabel(
            label: context.loc.hide, onClicked: (menuItem) => hideWindow()),
        MenuSeparator(),
        // Add all the services to the context menu
        MenuItemLabel(label: context.loc.copy_otp_for, enabled: false),
        for (var i = 0; i < itemModel.items.length; i++)
          MenuItemLabel(
            label: itemModel.items[i].service,
            onClicked: (menuItem) async {
              var key = itemModel.items[i];
              var otp = generateTOTP(key);
              Clipboard.setData(ClipboardData(text: otp));
            },
          ),
        MenuSeparator(),
        MenuItemLabel(
            label: context.loc.quit, onClicked: (menuItem) => exitApp())
      ]);

      // set context menu
      await systemTray.setContextMenu(menu);

      // handle system tray event
      systemTray.registerSystemTrayEventHandler((eventName) {
        debugPrint("eventName: $eventName");
        if (eventName == kSystemTrayEventClick) {
          isPlatformWindows()
              ? appWindow.show()
              : systemTray.popUpContextMenu();
        } else if (eventName == kSystemTrayEventRightClick) {
          isPlatformWindows()
              ? systemTray.popUpContextMenu()
              : appWindow.show();
        }
      });
    }
  }

  void loopRefresh() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (currentScreen != 0) {
        // If the user is not on the home screen, don't update the progress
        loopRefresh();
        return;
      }
      refresher.value = !refresher.value;
      loopRefresh();
    });
  }

  Widget otpListTile(KeyStruct key, Color color, int index, bool editMode) {
    return ListTile(
      mouseCursor: SystemMouseCursors.click,
      leading: editMode
          ? SizedBox(
              height: 32.0,
              width: 32.0,
              child: IconButton(
                padding: const EdgeInsets.all(0.0),
                iconSize: 15.0,
                icon: Icon(Icons.delete, size: 32.0, color: color),
                onPressed: () {
                  deleteDialog(key, index, context);
                },
              ),
            )
          : (key.iconBase64 == "")
              ? Icon(
                  Icons.key,
                  size: 32.0,
                  color: color,
                )
              : SizedBox(
                  height: 32.0,
                  width: 32.0,
                  child: Image.memory(
                    base64Decode(key.iconBase64),
                    gaplessPlayback: true,
                  )),
      title: Text(key.service,
          style: TextStyle(
              color: color, fontWeight: bold ? FontWeight.bold : null)),
      subtitle: (key.description != "")
          ? Text(key.description,
              style: TextStyle(
                  color: color,
                  fontSize: 10.0,
                  fontWeight: bold ? FontWeight.bold : null))
          : null,
      trailing: editMode
          ? SizedBox(
              height: 32.0,
              width: 32.0,
              child: IconButton(
                padding: const EdgeInsets.all(0.0),
                iconSize: 15.0,
                icon: Icon(Icons.edit, size: 32.0, color: color),
                onPressed: () {
                  editDialog(key, index, context);
                },
              ),
            )
          : Row(mainAxisSize: MainAxisSize.min, children: [
              // Add space in middle of code
              SizedBox(
                child: ValueListenableBuilder(
                    valueListenable: refresher,
                    builder: (context, value, child) {
                      int adjustedTimeMillis =
                          DateTime.now().millisecondsSinceEpoch + time;
                      var authCode = generateTOTP(key);
                      if (altProgress) {
                        return key.eightDigits
                            ? ProgressbarText(
                                text:
                                    "${authCode.substring(0, 4)} ${authCode.substring(4)}",
                                progress: (adjustedTimeMillis %
                                        (key.interval * 1000)) /
                                    (key.interval * 1000),
                                color: color)
                            : ProgressbarText(
                                text:
                                    "${authCode.substring(0, 3)} ${authCode.substring(3)}",
                                progress: (adjustedTimeMillis %
                                        (key.interval * 1000)) /
                                    (key.interval * 1000),
                                color: color);
                      } else {
                        return key.eightDigits
                            ? Text(
                                "${authCode.substring(0, 4)} ${authCode.substring(4)}",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: color,
                                    fontWeight: FontWeight.bold))
                            : Text(
                                "${authCode.substring(0, 3)} ${authCode.substring(3)}",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: color,
                                    fontWeight: FontWeight.bold));
                      }
                    }),
              ),
              // Progress bar of time left before code changes and update it automatically
              if (!altProgress)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ValueListenableBuilder(
                        valueListenable: refresher,
                        builder: (context, value, child) {
                          int adjustedTimeMillis =
                              DateTime.now().millisecondsSinceEpoch + time;
                          return CircularProgressIndicator(
                            // calculate progress seconds left until code changes (taking into account the time difference between device and server) "time" variable
                            value:
                                (adjustedTimeMillis % (key.interval * 1000)) /
                                    (key.interval * 1000),
                            strokeWidth: 5,
                            color: color,
                          );
                        },
                      ),
                    ),
                  ),
                )
            ]),
    );
  }

  var editMode = false;

  @override
  void initState() {
    super.initState();
    //updateProgress();
    initSystemTray();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int widthCard = 290;

    int heightCard = 70;

    if (width < widthCard) {
      widthCard = width.toInt() - 1;
    }

    int count = width ~/ widthCard;

    widthCard = width ~/ count;

    FloatingActionButton fab = FloatingActionButton(
      mini: (isPlatformMacos() || isPlatformWindows() || isPlatformLinux()),
      onPressed: () {
        if (!editMode) {
          currentScreen = 1;
          Navigator.pushNamed(context, "/addService");
        } else {
          setState(() {
            editMode = false;
          });
        }
      },
      tooltip: editMode ? context.loc.edit : context.loc.add_service_name,
      child: editMode ? const Icon(Icons.done) : const Icon(Icons.add),
    );

    //updateProgress();
    loopRefresh();
    return WillPopScope(
        onWillPop: () {
          if (editMode) {
            setState(() {
              editMode = false;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: (isPlatformMobile() || forceAppbar.value)
              ? AppBar(
                  title:
                      editMode ? Text(context.loc.editing) : Text(widget.title),
                  actions: [
                    // 3 dots menu
                    PopupMenuButton(
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                              value: 0, child: Text(context.loc.edit)),
                          PopupMenuItem(
                              value: 2,
                              child: Text(context.loc.home_import_export)),
                          PopupMenuItem(
                            value: 3,
                            child: Text(context.loc.home_about),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: Text(context.loc.home_settings),
                          ),
                        ];
                      },
                      onSelected: (int value) async {
                        switch (value) {
                          case 0:
                            setState(() {
                              editMode = !editMode;
                            });
                            break;
                          case 1:
                            currentScreen = 2;
                            Navigator.pushNamed(context, "/settings");
                            break;
                          case 2:
                            currentScreen = 3;
                            Navigator.pushNamed(context, "/importExport");
                            break;
                          case 3:
                            // Show about dialog
                            aboutDialog(context);
                            break;
                        }
                      },
                    )
                  ],
                )
              : PreferredSize(
                  preferredSize: const Size.fromHeight(40.0),
                  child: MyMenuBar(menuItems: [
                    SubMenuItem(title: "File", items: [
                      MenuItem(
                          title: context.loc.home_about,
                          onPressed: () {
                            aboutDialog(context);
                          }),
                      MenuItem(
                          title: context.loc.home_import_export,
                          onPressed: () {
                            currentScreen = 3;
                            Navigator.pushNamed(context, "/importExport");
                          }),
                      MenuItem(
                          title: context.loc.quit,
                          keybind: getShortcut(LogicalKeyboardKey.keyQ, true),
                          onPressed: () {
                            exitApp();
                          })
                    ]),
                    SubMenuItem(title: "Edit", items: [
                      MenuItem(
                          title: context.loc.add_service_name,
                          keybind: getShortcut(LogicalKeyboardKey.keyA, true),
                          onPressed: () {
                            if (currentScreen == 0) {
                              currentScreen = 1;
                              Navigator.pushNamed(context, "/addService");
                            }
                          }),
                      MenuItem(
                          title: context.loc.edit,
                          keybind: getShortcut(LogicalKeyboardKey.keyE, true),
                          onPressed: () {
                            setState(() {
                              editMode = !editMode;
                            });
                          }),
                      MenuItem(
                          title: context.loc.home_settings,
                          keybind: isPlatformMacos()
                              ? getShortcut(LogicalKeyboardKey.comma, true)
                              : getShortcut(LogicalKeyboardKey.keyS, true),
                          onPressed: () {
                            if (currentScreen == 0) {
                              currentScreen = 2;
                              Navigator.pushNamed(context, "/settings");
                            }
                          }),
                    ])
                  ])),
          body: Consumer<Keys>(builder: (context, itemModel, _) {
            initSystemTray();
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: gridViewBuilder(
                  count, widthCard, heightCard, itemModel.items),
            );
          }),
          floatingActionButton: isPlatformMobile()
              ? fab
              : ContextMenuRegion(
                  contextMenu: GenericContextMenu(buttonConfigs: [
                    if (!editMode)
                      ContextMenuButtonConfig(context.loc.add_service_name,
                          onPressed: () {
                        currentScreen = 1;
                        Navigator.pushNamed(context, "/addService");
                      }, icon: const Icon(Icons.add)),
                    if (!editMode)
                      ContextMenuButtonConfig(context.loc.home_import_export,
                          onPressed: () {
                        currentScreen = 3;
                        Navigator.pushNamed(context, "/importExport");
                      }, icon: const Icon(Icons.import_export)),
                    ContextMenuButtonConfig(context.loc.edit, onPressed: () {
                      setState(() {
                        editMode = !editMode;
                      });
                    }, icon: const Icon(Icons.edit))
                  ]),
                  child: fab),
        ));
  }

  ReorderableGridView gridViewBuilder(
      int count, int widthCard, int heightCard, List<KeyStruct> snapshot) {
    return ReorderableGridView.builder(
      //scrollDirection: Axis.vertical,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        //crossAxisSpacing: 8,
        childAspectRatio: (widthCard / heightCard),
      ),
      itemCount: snapshot.length,
      itemBuilder: (BuildContext context, int index) {
        var color = StructTools().getTextColor(snapshot[index].color);
        Widget card = MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: Card(
            clipBehavior: Clip.antiAlias,
            shadowColor: snapshot[index].color.withOpacity(0.5),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            color: Colors.white,
            child: Container(
              decoration: gradientBackground
                  ? BoxDecoration(
                      gradient: LinearGradient(colors: [
                      snapshot[index].color,
                      StructTools()
                          .getComplimentaryColor(snapshot[index].color),
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight))
                  : BoxDecoration(color: snapshot[index].color),
              child: Center(
                  child: otpListTile(snapshot[index], color, index, editMode)),
            ),
          ),
        );
        return GestureDetector(
            key: ValueKey(snapshot[index].key),
            onDoubleTap: editMode ? () async {} : null,
            onLongPress: editMode
                ? null
                : () async {
                    // Vibrate
                    vibrate(25);
                    setState(() {
                      editMode = true;
                    });
                  },
            child: isPlatformMobile()
                ? editMode
                    ? card
                    : AnimationPush(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                              text: generateTOTP(snapshot[index])));
                          // Show snackbar
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(context.loc.copied_to_clipboard),
                              duration: const Duration(seconds: 1),
                            ));
                          }
                        },
                        child: card)
                : ContextMenuRegion(
                    contextMenu: GenericContextMenu(buttonConfigs: [
                      ContextMenuButtonConfig(context.loc.copy, onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: generateTOTP(snapshot[index])));
                      }, icon: const Icon(Icons.copy)),
                      ContextMenuButtonConfig(
                          context.loc.home_context_menu_delete, onPressed: () {
                        deleteDialog(snapshot[index], index, context);
                      }, icon: const Icon(Icons.delete)),
                      ContextMenuButtonConfig(
                          context.loc.home_context_menu_edit, onPressed: () {
                        editDialog(snapshot[index], index, context);
                      }, icon: const Icon(Icons.edit)),
                    ]),
                    child: editMode
                        ? card
                        : AnimationPush(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                  text: generateTOTP(snapshot[index])));
                              // Show snackbar
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text(context.loc.copied_to_clipboard),
                                  duration: const Duration(seconds: 1),
                                ));
                              }
                            },
                            child: card)));
      },
      onReorder: (int oldIndex, int newIndex) {
        if (!editMode) {
          return;
        }
        setState(() {
          final itemModel = Provider.of<Keys>(context, listen: false);
          itemModel.removeItem(itemModel.items[oldIndex]);
        });
        KeyManagement().saveKeys(snapshot);
      },
    );
  }
}

var currentScreen = 0;
