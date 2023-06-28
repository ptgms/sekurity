import 'dart:convert';

import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:native_context_menu/native_context_menu.dart' as ctx;
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:sekurity/components/animation_push.dart';
import 'package:sekurity/components/menubar.dart';
import 'package:sekurity/components/platform/platform_appbar.dart';
import 'package:sekurity/components/platform/platform_fab.dart';
import 'package:sekurity/components/platform/platform_popup_button.dart';
import 'package:sekurity/components/platform/platform_scaffold.dart';
import 'package:sekurity/components/progress_text.dart';
import 'package:sekurity/views/homescreen_dialogs.dart';
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
    if (isPlatformMobile()) {
      return;
    }
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

  Widget? otpIcon(bool isHabbit, KeyStruct key, Color color, bool isCard) {
    if (isHabbit) {
      return null;
    }
    var icon = (key.iconBase64 == "")
        ? Icon(
            Icons.key,
            size: isCard? 32.0 : 24.0,
            color: isCard ? color : null,
          )
        : SizedBox(
            height: isCard? 32.0 : 24.0,
            width: isCard? 32.0 : 24.0,
            child: Image.memory(
              base64Decode(key.iconBase64),
              gaplessPlayback: true,
            ));

    if (!isCard) {
      return Card(color: key.color, child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: icon,
      ));
    }
    return icon;
  }

  Widget otpListTile(KeyStruct key, Color color, int index, bool editMode) {
    bool isCard = displayStyle == AppStyle.cards;
    bool isHabbit = displayStyle == AppStyle.habbit;
    return ListTile(
      mouseCursor: SystemMouseCursors.click,
      leading: editMode
          ? SizedBox(
              height: 32.0,
              width: 32.0,
              child: IconButton(
                padding: const EdgeInsets.all(0.0),
                iconSize: 15.0,
                icon: Icon(Icons.delete,
                    size: 32.0, color: isCard ? color : null),
                onPressed: () {
                  deleteDialog(key, index, context);
                },
              ),
            )
          : otpIcon(isHabbit, key, color, isCard),
      title: Text(key.service,
          maxLines: 1,
          style: TextStyle(
              color: isCard ? color : null,
              fontWeight: bold ? FontWeight.bold : null)),
      subtitle: (key.description != "")
          ? Text(key.description,
              maxLines: 1,
              style: TextStyle(
                  color: isCard ? color : null,
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
                                color: isCard
                                    ? color
                                    : Theme.of(context).colorScheme.secondary)
                            : ProgressbarText(
                                text:
                                    "${authCode.substring(0, 3)} ${authCode.substring(3)}",
                                progress: (adjustedTimeMillis %
                                        (key.interval * 1000)) /
                                    (key.interval * 1000),
                                color: isCard
                                    ? color
                                    : Theme.of(context).colorScheme.secondary);
                      } else {
                        return key.eightDigits
                            ? Text(
                                "${authCode.substring(0, 4)} ${authCode.substring(4)}",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isCard ? color : null,
                                    fontWeight: FontWeight.bold))
                            : Text(
                                "${authCode.substring(0, 3)} ${authCode.substring(3)}",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: isCard ? color : null,
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
                            color: isCard
                                ? color
                                : Theme.of(context).textTheme.bodyMedium!.color,
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

    int heightCard = (isPlatformIOS() ? 80 : 70);

    if (width < widthCard) {
      widthCard = width.toInt() - 1;
    }

    int count = width ~/ widthCard;

    widthCard = width ~/ count;

    Widget fab = PlatformFloatingActionButton(
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
      icon: editMode ? const Icon(Icons.done) : const Icon(Icons.add),
    );

    ScrollController controller = ScrollController();
    bool fabVisible = true;

    controller.addListener(() {
      if (controller.position.userScrollDirection == ScrollDirection.reverse) {
        if (fabVisible == true) {
          setState(() {
            fabVisible = false;
          });
        }
      } else {
        if (controller.position.userScrollDirection ==
            ScrollDirection.forward) {
          if (fabVisible == false) {
            setState(() {
              fabVisible = true;
            });
          }
        }
      }
    });

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
        child: PlatformScaffold(
            appBar: PlatformAppBar(
                title: editMode ? context.loc.editing : widget.title,
                actions: [
                  PlatformPopupMenuButton(items: [
                    PlatformButton(
                        text: context.loc.edit,
                        onPressed: () {
                          setState(() {
                            editMode = !editMode;
                          });
                        }),
                    PlatformButton(
                        text: context.loc.home_import_export,
                        onPressed: () {
                          currentScreen = 3;
                          Navigator.pushNamed(context, "/importExport");
                        }),
                    PlatformButton(
                        text: context.loc.home_about,
                        onPressed: () => aboutDialog(context)),
                    PlatformButton(
                        text: context.loc.home_settings,
                        onPressed: () {
                          currentScreen = 2;
                          Navigator.pushNamed(context, "/settings");
                        }),
                  ]),
                ],
                menuItems: [
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
                ]),
            body: Consumer<Keys>(builder: (context, itemModel, _) {
              initSystemTray();
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: gridViewBuilder(
                    count, widthCard, heightCard, itemModel.items, controller),
              );
            }),
            floatingActionButton: Visibility(
              visible: fabVisible,
              child: isPlatformMobile()
                  ? fab
                  : ctx.ContextMenuRegion(
                      onItemSelected: (item) {
                        item.onSelected?.call();
                      },
                      menuItems: [
                        if (!editMode)
                          ctx.MenuItem(
                              title: context.loc.add_service_name,
                              onSelected: () {
                                currentScreen = 1;
                                Navigator.pushNamed(context, "/addService");
                              }),
                        if (!editMode)
                          ctx.MenuItem(
                              title: context.loc.home_import_export,
                              onSelected: () {
                                currentScreen = 3;
                                Navigator.pushNamed(context, "/importExport");
                              }),
                        ctx.MenuItem(
                            title: context.loc.edit,
                            onSelected: () {
                              setState(() {
                                editMode = !editMode;
                              });
                            }),
                      ],
                      child: fab),
            )));
  }

  Widget gridViewBuilder(int count, int widthCard, int heightCard,
      List<KeyStruct> snapshot, ScrollController controller) {
    return ReorderableGridView.builder(
      controller: controller,
      //scrollDirection: Axis.vertical,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count,
        //crossAxisSpacing: 8,
        childAspectRatio: (widthCard / (heightCard * (bigCards ? 1.3 : 1))),
      ),
      itemCount: snapshot.length,
      itemBuilder: (BuildContext context, int index) {
        var color = StructTools().getTextColor(snapshot[index].color);
        Widget card = MouseRegion(
            cursor: SystemMouseCursors.basic,
            child: displayStyle == AppStyle.cards
                ? cardStyle(snapshot, index, heightCard, color)
                : displayStyle == AppStyle.minimalistic
                    ? otpListTile(snapshot[index], color, index, editMode)
                    : otpListTile(snapshot[index], color, index, editMode));
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
                          if (context.mounted && !isPlatformAndroid()) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(context.loc.copied_to_clipboard),
                              duration: const Duration(seconds: 1),
                            ));
                          }
                        },
                        child: card)
                : ctx.ContextMenuRegion(
                    onItemSelected: (item) {
                      item.onSelected?.call();
                    },
                    menuItems: [
                      ctx.MenuItem(
                          title: context.loc.copy,
                          onSelected: () {
                            Clipboard.setData(ClipboardData(
                                text: generateTOTP(snapshot[index])));
                          }),
                      ctx.MenuItem(
                          title: context.loc.home_context_menu_delete,
                          onSelected: () {
                            deleteDialog(snapshot[index], index, context);
                          }),
                      ctx.MenuItem(
                          title: context.loc.home_context_menu_edit,
                          onSelected: () {
                            editDialog(snapshot[index], index, context);
                          }),
                    ],
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

  Card cardStyle(
      List<KeyStruct> snapshot, int index, int heightCard, Color color) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shadowColor: snapshot[index].color.withOpacity(0.5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular((heightCard * (bigCards ? 1.3 : 1)) / 2),
      ),
      color: Colors.white,
      child: Container(
        decoration: gradientBackground
            ? BoxDecoration(
                gradient: LinearGradient(colors: [
                snapshot[index].color,
                StructTools().getComplimentaryColor(snapshot[index].color),
              ], begin: Alignment.topLeft, end: Alignment.bottomRight))
            : BoxDecoration(color: snapshot[index].color),
        child:
            Center(child: otpListTile(snapshot[index], color, index, editMode)),
      ),
    );
  }
}

var currentScreen = 0;
