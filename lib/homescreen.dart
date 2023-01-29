import 'dart:convert';
//import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ValueNotifier<List<double>> progress = ValueNotifier(List<double>.filled(0, 0));

  void updateProgress() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      var keys = await KeyManagement().getSavedKeys();

      if (keys.isEmpty) {
        return;
      }

      var newProg = List<double>.filled(keys.length, 0);

      for (var i = 0; i < keys.length; i++) {
        newProg[i] = 1 - ((DateTime.now().millisecondsSinceEpoch % (keys[i].interval * 1000)) / (keys[i].interval * 1000));
      }

      progress.value = newProg;
      updateProgress();
    });
  }

  Widget OTPListTile(KeyStruct key, Color color, int index) {
    return ListTile(
      leading: (key.iconBase64 == "")
          ? Icon(
              Icons.key,
              size: 32.0,
              color: color,
            )
          : SizedBox(height: 32.0, width: 32.0, child: Image.memory(base64Decode(key.iconBase64))),
      title: Text(key.service, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : null)),
      subtitle:
          (key.description != "") ? Text(key.description, style: TextStyle(color: color, fontSize: 12.0, fontWeight: bold ? FontWeight.bold : null)) : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // Add space in middle of code
        ValueListenableBuilder(
            valueListenable: progress,
            builder: (context, value, child) {
              var authCode = TOTP(secret: key.key, digits: key.eightDigits ? 8 : 6, interval: key.interval, algorithm: key.algorithm).now();
              return key.eightDigits
                  ? PlatformText("${authCode.substring(0, 4)} ${authCode.substring(4)}",
                      style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold))
                  : PlatformText("${authCode.substring(0, 3)} ${authCode.substring(3)}",
                      style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold));
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
                valueListenable: progress,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value[index],
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
      if ((event.isControlPressed && event.logicalKey.keyId == 0x73) || (event.isMetaPressed && event.logicalKey.keyId == 0x2c)) {
        // Only navigate if current screen is home
        if (currentScreen == 0) {
          currentScreen = 2;
          Navigator.of(context).pushNamed("/settings");
        }
      }
    });

    var appBar = PlatformAppBar(
      title: Text(widget.title),
      trailingActions: [
        // 3 dots menu
        PopupMenuButton(
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 1,
                child: Text(context.loc.home_settings),
              ),
              PopupMenuItem(value: 2, child: Text(context.loc.home_import_export)),
              PopupMenuItem(
                value: 3,
                child: Text(context.loc.home_about),
              ),
            ];
          },
          onSelected: (int value) async {
            switch (value) {
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
                showPlatformDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(context.loc.home_about),
                    content: Text(context.loc.home_about_description),
                    actions: [
                      PlatformDialogAction(
                        child: const Text("ptgms"),
                        onPressed: () async {
                          await launchUrl(Uri.parse("https://github.com/ptgms"));
                        },
                      ),
                      PlatformDialogAction(
                        child: const Text("SphericalKat"),
                        onPressed: () async {
                          await launchUrl(Uri.parse("https://github.com/SphericalKat"));
                        },
                      ),
                      PlatformDialogAction(
                        child: Text(context.loc.dialog_close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
                break;
            }
          },
        ),
        (isPlatformWindows() || isPlatformLinux()) ? const WindowButtons() : Container()
      ],
    );

    double width = MediaQuery.of(context).size.width;
    int widthCard = 400;

    int heightCard = 90;

    if (width < widthCard) {
      widthCard = width.toInt() - 1;
    }

    int count = width ~/ widthCard;

    widthCard = width ~/ count;

    updateProgress();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: (isPlatformWindows() || isPlatformLinux() || isPlatformMacos()) ? MoveWindow(child: appBar) : appBar,
      ),
      body: FutureBuilder(
        future: KeyManagement().getSavedKeys(),
        builder: (BuildContext context, AsyncSnapshot<List<KeyStruct>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(child: Text(context.loc.home_no_keys));
            }
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ValueListenableBuilder(
                valueListenable: KeyManagement().version,
                builder: (context, value, child) {
                  return GridView.builder(
                    scrollDirection: Axis.vertical,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      childAspectRatio: (widthCard / heightCard),
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      var color = StructTools().getTextColor(snapshot.data![index].color);
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Card(
                          color: snapshot.data![index].color,
                          child: Center(
                            child: InkWell(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(
                                    text: TOTP(
                                            secret: snapshot.data![index].key,
                                            digits: snapshot.data![index].eightDigits ? 8 : 6,
                                            interval: snapshot.data![index].interval,
                                            algorithm: snapshot.data![index].algorithm)
                                        .now()));
                                // Show snackbar
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(context.loc.copied_to_clipboard),
                                    duration: const Duration(seconds: 1),
                                  ));
                                }
                              },
                              onLongPress: () {
                                // Show menu to delete
                                showPlatformDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(context.loc.home_delete_confirm(snapshot.data![index].service)),
                                    content: Text(context.loc.home_delete_confirm_description(snapshot.data![index].service)),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(context.loc.home_delete_confirm_no),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Delete key
                                          var keys = await KeyManagement().getSavedKeys();
                                          setState(() {
                                            keys.removeAt(index);
                                          });
                                          await KeyManagement().saveKeys(keys);
                                          if (context.mounted) Navigator.of(context).pop();
                                        },
                                        child: Text(context.loc.home_delete_confirm_yes),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: OTPListTile(snapshot.data![index], color, index),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          } else {
            return Center(child: PlatformCircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: (isPlatformMacos() || isPlatformWindows() || isPlatformLinux()),
        onPressed: () {
          currentScreen = 1;
          Navigator.pushNamed(context, "/addService");
        },
        tooltip: context.loc.add_service_name,
        child: const Icon(Icons.add),
      ),
    );
  }
}

var currentScreen = 0;
