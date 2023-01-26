import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otp/otp.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:sekurity/tools/keymanagement.dart';

class AddService extends StatefulWidget {
  const AddService({super.key});

  @override
  State<AddService> createState() => _AddServiceState();
}

class _AddServiceState extends State<AddService> {
  ValueNotifier<KeyStruct> keyStruct = ValueNotifier(KeyStruct(iconBase64: "", key: "", service: "", color: Colors.blue, description: ""));

  var isManual = false;
  @override
  Widget build(BuildContext context) {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      // Escape = Cancel
      if (event.logicalKey.keyId == 0x1000000) {
        Navigator.of(context).pop();
      }
    });
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: PlatformAppBar(
          title: Text("Add Service"),
        ),
      ),
      body: (isManual || (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) ? manualMode() : mobileView(),
    );
  }

  Widget mobileView() {
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
                      if (context.mounted) Navigator.of(context).pop();
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
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
                    child: Text("Add Service Manually"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget manualMode() {
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
                          if (Platform.isAndroid || Platform.isIOS) {
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
                                const Text("Set Service Icon"),
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
                                        title: const Text("Select Color"),
                                        content: SingleChildScrollView(
                                          child: ColorPicker(
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
                                            pickerAreaHeightPercent: 0.8,
                                          ),
                                        ),
                                        actions: [
                                          PlatformTextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("Close"),
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
                                      Text("Set Service Color", style: TextStyle(color: StructTools().getTextColor(keyStruct.color))),
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
                          child: Expanded(
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
                            decoration: const InputDecoration(border: InputBorder.none, labelText: "Service Name"),
                          )),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: Expanded(
                              child: TextField(
                            onChanged: (value) {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: value,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: keyStruct.value.description);
                            },
                            decoration: const InputDecoration(border: InputBorder.none, labelText: "Secret Key"),
                          )),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: Expanded(
                              child: TextField(
                            onChanged: (value) {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: keyStruct.value.key,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: value);
                            },
                            decoration: const InputDecoration(border: InputBorder.none, labelText: "Description"),
                          )),
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
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      child: const Text("Add Service"),
                    ),
                  ),
                  !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)
                      ? Expanded(
                          child: PlatformTextButton(
                            onPressed: () {
                              setState(() {
                                isManual = false;
                              });
                            },
                            child: const Text("Scan QR Code"),
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
