import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:otp/otp.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ValueNotifier<double> progress = ValueNotifier(0.0);

  void updateProgress() {
    Future.delayed(const Duration(milliseconds: 10), () {
      // reverse progress
      progress.value = 1 - ((DateTime.now().millisecondsSinceEpoch % 30000) / 30000);
      updateProgress();
    });
  }

  Widget OTPListTile(KeyStruct key, Color color) {
    return ListTile(
      leading: (key.iconBase64 == "")
          ? const Icon(
              Icons.image,
              size: 32.0,
            )
          : SizedBox(height: 32.0, width: 32.0, child: Image.memory(base64Decode(key.iconBase64))),
      title: Text(key.service, style: TextStyle(color: color)),
      subtitle: (key.description != "") ? Text(key.description, style: TextStyle(color: color, fontSize: 12.0)) : null,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // Add space in middle of code
        ValueListenableBuilder(
            valueListenable: progress,
            builder: (context, value, child) {
              var authCode = OTP.generateTOTPCodeString(key.key, DateTime.now().millisecondsSinceEpoch);
              return PlatformText("${authCode.substring(0, 3)} ${authCode.substring(3)}",
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
                builder: (BuildContext context, double value, Widget? child) {
                  return CircularProgressIndicator(
                    value: value,
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
        Navigator.of(context).pushNamed("/addService");
      }
    });
    updateProgress();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: PlatformAppBar(
          title: Text(widget.title),
          trailingActions: [
            // 3 dots menu
            PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return const [
                  PopupMenuItem(
                    value: 0,
                    child: Text("Clear all keys"),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Text("Settings"),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text("About"),
                  ),
                ];
              },
              onSelected: (int value) async {
                switch (value) {
                  case 0:
                    await KeyManagement().saveKeys(List<KeyStruct>.empty(growable: true));
                    break;
                  case 1:
                    // Settings
                    break;
                  case 2:
                    // Show about dialog
                    showPlatformDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("About"),
                        content: const Text("Sekurity\nMade by ptgms and SphericalKat"),
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
                            child: const Text("Close"),
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
          ],
        ),
      ),
      body: FutureBuilder(
        future: KeyManagement().getSavedKeys(),
        builder: (BuildContext context, AsyncSnapshot<List<KeyStruct>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text("No keys saved, add one with the + button"));
            }
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: ValueListenableBuilder(
                  valueListenable: KeyManagement().version,
                  builder: (context, _, __) {
                    double width = MediaQuery.of(context).size.width;
                    int widthCard = 400;

                    int heightCard = 72;

                    if (width < widthCard) {
                      widthCard = width.toInt() - 1;
                    }

                    int count = width ~/ widthCard;

                    widthCard = width ~/ count;
                    return GridView.builder(
                      scrollDirection: Axis.vertical,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        childAspectRatio: (widthCard / heightCard),
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        var color = StructTools().getTextColor(snapshot.data![index].color);
                        return Card(
                          color: snapshot.data![index].color,
                          child: Center(
                            child: InkWell(
                              onTap: () async {
                                // Copy to clipboard
                                await Clipboard.setData(
                                    ClipboardData(text: OTP.generateTOTPCodeString(snapshot.data![index].key, DateTime.now().millisecondsSinceEpoch)));
                                // Show snackbar
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text("Copied to clipboard!"),
                                    duration: Duration(seconds: 1),
                                  ));
                                }
                              },
                              onLongPress: () {
                                // Show menu to delete
                                showPlatformDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text("Delete your ${snapshot.data![index].service} key?"),
                                    content: Text(
                                        "Are you sure you want to delete your ${snapshot.data![index].service} key? You can't undo this action and you may not be able to log in to your account anymore."),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          // Delete key
                                          var keys = await KeyManagement().getSavedKeys();
                                          keys.removeAt(index);
                                          await KeyManagement().saveKeys(keys);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: OTPListTile(snapshot.data![index], color),
                            ),
                          ),
                        );
                      },
                    );
                  }),
            );
          } else {
            return Center(child: PlatformCircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/addService");
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}
