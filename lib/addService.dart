import 'dart:convert';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sekurity/main.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'homescreen.dart';

class AddService extends StatefulWidget {
  const AddService({super.key});

  @override
  State<AddService> createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  ValueNotifier<KeyStruct> keyStruct = ValueNotifier(KeyStruct(iconBase64: "", key: "", service: "", color: Colors.blue, description: ""));

  var isManual = false;
  var isEscaped = false;
  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);

    RawKeyboard.instance.addListener((RawKeyEvent event) {
      // Escape = Cancel
      if (isEscaped) return;
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        isEscaped = true;
        currentScreen = 0;
        Navigator.of(context).pop();
      }
    });

    var appBar = PlatformAppBar(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          (isPlatformMacos()) ? const SizedBox(width: 40) : Container(),
          PlatformIconButton(
            icon: Icon(PlatformIcons(context).back),
            onPressed: () {
              Navigator.of(context).pop();
              currentScreen = 0;
            },
          ),
        ],
      ),
      trailingActions: [
        (isPlatformWindows() || isPlatformLinux()) ? const WindowButtons() : Container(),
      ],
      title: Text(context.loc.add_service_name),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: (isPlatformWindows() || isPlatformLinux() || isPlatformMacos()) ? MoveWindow(child: appBar) : appBar,
      ),
      body: (isManual || (isPlatformWindows() || isPlatformLinux() || isPlatformMacos())) ? manualMode(context) : mobileView(context),
    );
  }

  Widget mobileView(BuildContext context) {
    var locale = AppLocalizations.of(context)!;
    var scanned = false;
    // Camera preview with QR code scanner and button to add service manually
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: QRView(
                formatsAllowed: const [BarcodeFormat.qrcode],
                overlay: QrScannerOverlayShape(
                    borderColor: Colors.red, borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: 300, overlayColor: Colors.black.withOpacity(0.5)),
                key: GlobalKey(debugLabel: 'QR'),
                onQRViewCreated: (QRViewController controller) {
                  controller.scannedDataStream.listen((scanData) async {
                    if (scanned || scanData.code == null) return;
                    scanned = true;
                    if (await KeyManagement().addKeyQR(scanData.code!)) {
                      KeyManagement().version.value++;
                      if (context.mounted) {
                        currentScreen = 0;
                        Navigator.of(context).pop();
                      }
                    }
                  });
                },
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: PlatformTextButton(
                  onPressed: () {
                    setState(() {
                      isManual = true;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: Text(context.loc.service_manual),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget manualMode(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            scrollDirection: Axis.vertical,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    child: InkWell(
                        onTap: () async {
                          if (isPlatformMobile()) {
                            // Image picker
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              // Make image square and resize to 64x64
                              var imageBytes = StructTools().cropAndResizeImage(base64Encode(await image.readAsBytes()));
                              keyStruct.value.iconBase64 = imageBytes;
                            }
                          } else {
                            // File picker
                            final FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );

                            if (result != null) {
                              final File file = File(result.files.single.path!);
                              // Make image square and resize to 64x64
                              var imageBytes = StructTools().cropAndResizeImage(base64Encode(await file.readAsBytes()));
                              keyStruct.value.iconBase64 = imageBytes;
                            } else {
                              // User canceled the picker
                            }
                          }
                        },
                        child: SizedBox(
                          height: 64.0,
                          width: 180.0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                ValueListenableBuilder(
                                    valueListenable: keyStruct,
                                    builder: (_, keyStruct, __) => Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: (keyStruct.iconBase64 == "")
                                              ? const Icon(
                                                  Icons.image,
                                                  size: 32.0,
                                                )
                                              : SizedBox(height: 32.0, width: 32.0, child: Image.memory(base64Decode(keyStruct.iconBase64))),
                                        )),
                                Text(context.loc.service_icon),
                              ],
                            ),
                          ),
                        )),
                  ),
                  ValueListenableBuilder(
                      valueListenable: keyStruct,
                      builder: (_, keyStruct, __) {
                        return Card(
                          color: keyStruct.color,
                          child: InkWell(
                              onTap: () {
                                // Dialog to select color
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(context.loc.service_color_dialog),
                                        content: SingleChildScrollView(
                                          child: ColorPicker(
                                            colorPickerWidth: (MediaQuery.of(context).size.width < 800 && MediaQuery.of(context).size.height > 800) ? 75 : 300,
                                            labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex],
                                            enableAlpha: false,
                                            pickerColor: keyStruct.color,
                                            onColorChanged: (color) {
                                              this.keyStruct.value = KeyStruct(
                                                  iconBase64: keyStruct.iconBase64,
                                                  key: keyStruct.key,
                                                  service: keyStruct.service,
                                                  color: color,
                                                  description: keyStruct.description);
                                            },
                                          ),
                                        ),
                                        actions: [
                                          PlatformTextButton(
                                            onPressed: () {
                                              currentScreen = 0;
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(context.loc.dialog_close),
                                          ),
                                        ],
                                      );
                                    });
                              },
                              child: SizedBox(
                                height: 64.0,
                                width: 180.0,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.color_lens, color: StructTools().getTextColor(keyStruct.color)),
                                      ),
                                      Text(context.loc.service_color, style: TextStyle(color: StructTools().getTextColor(keyStruct.color))),
                                    ],
                                  ),
                                ),
                              )),
                        );
                      }),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: TextField(
                            onChanged: (value) async {
                              final defaultServices = await rootBundle.loadString('assets/services.json');
                              // Structure: { "discord": { "color": 4283983346, "icon": "base64"} }

                              var color = keyStruct.value.color;
                              var icon = keyStruct.value.iconBase64;

                              if (jsonDecode(defaultServices).containsKey(value.toLowerCase())) {
                                // Get color and icon from json
                                color = Color(jsonDecode(defaultServices)[value.toLowerCase()]["color"]);
                                icon = jsonDecode(defaultServices)[value.toLowerCase()]["icon"];
                              }

                              keyStruct.value =
                                  KeyStruct(iconBase64: icon, key: keyStruct.value.key, service: value, color: color, description: keyStruct.value.description);
                            },
                            decoration: InputDecoration(border: InputBorder.none, labelText: context.loc.service_name),
                          ),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: TextField(
                            onChanged: (value) {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: value,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: keyStruct.value.description);
                            },
                            decoration: InputDecoration(border: InputBorder.none, labelText: context.loc.service_key),
                          ),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: TextField(
                            onChanged: (value) {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: keyStruct.value.key,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: value);
                            },
                            decoration: InputDecoration(border: InputBorder.none, labelText: context.loc.service_description),
                          ),
                        ),
                      ],
                    ),
                  )),
              Row(
                children: [
                  Expanded(
                    child: PlatformTextButton(
                      onPressed: () async {
                        // Add service to database
                        if (await KeyManagement().addKeyManual(keyStruct.value)) {
                          KeyManagement().version.value++;
                          if (context.mounted) {
                            currentScreen = 0;
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: Text(context.loc.add_service_name),
                    ),
                  ),
                  !(isPlatformWindows() || isPlatformLinux() || isPlatformMacos())
                      ? Expanded(
                          child: PlatformTextButton(
                            onPressed: () {
                              setState(() {
                                isManual = false;
                              });
                            },
                            child: Text(context.loc.service_qr),
                          ),
                        )
                      : Container(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
