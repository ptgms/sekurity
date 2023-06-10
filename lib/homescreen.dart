import 'dart:convert';

import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:system_tray/system_tray.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import 'main.dart';

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
    await menu.buildFrom([
      MenuItemLabel(label: context.loc.show, onClicked: (menuItem) => showWindow()),
      MenuItemLabel(label: context.loc.hide, onClicked: (menuItem) => hideWindow()),
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
      MenuItemLabel(label: context.loc.quit, onClicked: (menuItem) => exitApp())
    ]);

    // set context menu
    await systemTray.setContextMenu(menu);

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        isPlatformWindows() ? appWindow.show() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        isPlatformWindows() ? systemTray.popUpContextMenu() : appWindow.show();
      }
    });
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

  Widget OTPListTile(KeyStruct key, Color color, int index, bool editMode) {
    return ListTile(
      leading: editMode
          ? IconButton(
              icon: Icon(Icons.delete, size: 30.0, color: color),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.loc.home_delete_confirm(key.service)),
                    content: Text(context.loc
                        .home_delete_confirm_description(key.service)),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(context.loc.home_delete_confirm_no),
                      ),
                      TextButton(
                        onPressed: () async {
                          final itemModel =
                              Provider.of<Keys>(context, listen: false);
                          // Delete key

                          setState(() {
                            itemModel.removeItem(key);
                          });
                          await KeyManagement().saveKeys(itemModel.items);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(context.loc.home_delete_confirm_yes),
                      ),
                    ],
                  ),
                );
              },
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
                  child: Image.memory(base64Decode(key.iconBase64))),
      title: Text(key.service,
          style: TextStyle(
              color: color, fontWeight: bold ? FontWeight.bold : null)),
      subtitle: (key.description != "")
          ? Text(key.description,
              style: TextStyle(
                  color: color,
                  fontSize: 12.0,
                  fontWeight: bold ? FontWeight.bold : null))
          : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // Add space in middle of code
        ValueListenableBuilder(
            valueListenable: refresher,
            builder: (context, value, child) {
              var authCode = generateTOTP(key);
              return key.eightDigits
                  ? Text("${authCode.substring(0, 4)} ${authCode.substring(4)}",
                      style: TextStyle(
                          fontSize: 20,
                          color: color,
                          fontWeight: FontWeight.bold))
                  : Text("${authCode.substring(0, 3)} ${authCode.substring(3)}",
                      style: TextStyle(
                          fontSize: 20,
                          color: color,
                          fontWeight: FontWeight.bold));
            }),
        // Progress bar of time left before code changes and update it automatically
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
                    value: (adjustedTimeMillis % (key.interval * 1000)) /
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
    // Keyboard shortcuts
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      // Ctrl + A = Add service
      if (event.isControlPressed && event.logicalKey.keyId == 0x61) {
        // Only navigate if current screen is home
        if (currentScreen == 0) {
          currentScreen = 1;
          Navigator.of(context).pushNamed("/addService");
        }
      }

      // Ctrl + S or Cmd + , on macOS = Settings
      if ((event.isControlPressed && event.logicalKey.keyId == 0x73) ||
          (event.isMetaPressed && event.logicalKey.keyId == 0x2c)) {
        // Only navigate if current screen is home
        if (currentScreen == 0) {
          currentScreen = 2;
          Navigator.of(context).pushNamed("/settings");
        }
      }
    });

    var appBar = AppBar(
      title: editMode ? Text(context.loc.editing) : Text(widget.title),
      actions: [
        // 3 dots menu
        PopupMenuButton(
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(value: 0, child: Text(context.loc.edit)),
              PopupMenuItem(
                  value: 2, child: Text(context.loc.home_import_export)),
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
                showAboutDialog(
                    context: context,
                    applicationIcon: Image.asset(
                      "assets/app_icon.png",
                      width: 64,
                      height: 64,
                    ),
                    applicationName: "Sekurity",
                    applicationVersion: "1.0.0",
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(children: [
                          Text(context.loc.home_about_description),
                          Row(
                            children: [
                              // 2 Image buttons
                              Expanded(
                                child: TextButton(
                                  child: const Text("ptgms"),
                                  onPressed: () async {
                                    await launchUrl(
                                        Uri.parse("https://github.com/ptgms"));
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextButton(
                                  child: const Text("SphericalKat"),
                                  onPressed: () async {
                                    await launchUrl(Uri.parse(
                                        "https://github.com/SphericalKat"));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ]);
                break;
            }
          },
        )
      ],
    );

    double width = MediaQuery.of(context).size.width;
    int widthCard = 300;

    int heightCard = 94;

    if (width < widthCard) {
      widthCard = width.toInt() - 1;
    }

    int count = width ~/ widthCard;

    widthCard = width ~/ count;

    //updateProgress();
    loopRefresh();
    return Scaffold(
      appBar: appBar,
      body: Consumer<Keys>(builder: (context, itemModel, _) {
        initSystemTray();
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: gridViewBuilder(count, widthCard, heightCard, itemModel.items),
        );
      }),
      floatingActionButton: FloatingActionButton(
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
      ),
    );
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
        return GestureDetector(
            key: ValueKey(snapshot[index].key),
            onTap: editMode
                ? () async {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.loc.home_edit_info),
                        duration: const Duration(seconds: 1),
                      ));
                    }
                  }
                : () async {
                    await Clipboard.setData(
                        ClipboardData(text: generateTOTP(snapshot[index])));
                    // Show snackbar
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.loc.copied_to_clipboard),
                        duration: const Duration(seconds: 1),
                      ));
                    }
                  },
            onDoubleTap: editMode ? () async {} : null,
            onLongPress: editMode
                ? null
                : () async {
                    // Vibrate
                    if (isPlatformMobile() &&
                        (await Vibration.hasVibrator() ?? false)) {
                      Vibration.vibrate(duration: 50);
                    }
                    setState(() {
                      editMode = true;
                    });
                  },
            child: Card(
              color: snapshot[index].color,
              child: Center(
                  child: OTPListTile(snapshot[index], color, index, editMode)),
            ));
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
