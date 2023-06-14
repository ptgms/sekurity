import 'dart:convert';
import 'dart:io';

import 'package:dart_dash_otp/dart_dash_otp.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sekurity/main.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'homescreen.dart';

class EditService extends StatefulWidget {
  const EditService({super.key});

  @override
  State<EditService> createState() => _EditServiceState();
}

class _EditServiceState extends State<EditService> {
  ValueNotifier<KeyStruct> keyStruct = ValueNotifier(KeyStruct(
      iconBase64: "",
      key: "",
      service: "",
      color: StructTools().randomColorGenerator(),
      description: ""));
  var isEscaped = false;
  @override
  Widget build(BuildContext context) {
    RawKeyboard.instance.addListener((RawKeyEvent event) {
      // Escape = Cancel
      if (isEscaped) return;
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        isEscaped = true;
        currentScreen = 0;
        Navigator.of(context).pop();
      }
    });

    var appBar = AppBar(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
              currentScreen = 0;
            },
          ),
        ],
      ),
      title: Text(context.loc.edit_service_name),
    );

    return Scaffold(
      appBar: appBar,
      body: editService(context),
    );
  }

  Widget editService(BuildContext context) {
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
                children: [
                  ValueListenableBuilder(
                    valueListenable: keyStruct,
                    builder: (context, value, child) {
                      return SizedBox(
                          height: 70,
                          width: 70,
                          child: Card(
                              color: value.color,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: (value.iconBase64 == "")
                                    ? const Icon(
                                        Icons.key,
                                        size: 32.0,
                                      )
                                    : SizedBox(
                                        height: 32.0,
                                        width: 32.0,
                                        child: Image.memory(
                                            base64Decode(value.iconBase64))),
                              )));
                    },
                  ),
                ],
              ),
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
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery);
                            if (image != null) {
                              // Make image square and resize to 64x64
                              var imageBytes = StructTools().cropAndResizeImage(
                                  base64Encode(await image.readAsBytes()));
                              keyStruct.value.iconBase64 = imageBytes;
                            }
                          } else {
                            // File picker
                            final FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );

                            if (result != null) {
                              final File file = File(result.files.single.path!);
                              // Make image square and resize to 64x64
                              var imageBytes = StructTools().cropAndResizeImage(
                                  base64Encode(await file.readAsBytes()));
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    height: 32.0,
                                    width: 32.0,
                                    child: Icon(Icons.web)),
                                Text(context.loc.service_icon),
                              ],
                            ),
                          ),
                        )),
                  ),
                  Card(
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
                                      portraitOnly: true,
                                      pickerAreaHeightPercent: 0.5,
                                      labelTypes: const [ColorLabelType.rgb],
                                      enableAlpha: false,
                                      pickerColor: keyStruct.value.color,
                                      onColorChanged: (color) {
                                        keyStruct.value = KeyStruct(
                                            iconBase64:
                                                keyStruct.value.iconBase64,
                                            key: keyStruct.value.key,
                                            service: keyStruct.value.service,
                                            color: color,
                                            description:
                                                keyStruct.value.description,
                                            interval: keyStruct.value.interval,
                                            eightDigits:
                                                keyStruct.value.eightDigits,
                                            algorithm:
                                                keyStruct.value.algorithm);
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Icons.color_lens),
                                ),
                                Text(context.loc.service_color),
                              ],
                            ),
                          ),
                        )),
                  )
                ],
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: TextField(
                            onChanged: (value) async {
                              final defaultServices = await rootBundle
                                  .loadString('assets/services.json');
                              // Structure: { "discord": { "color": 4283983346, "icon": "base64"} }

                              var color = keyStruct.value.color;
                              var icon = keyStruct.value.iconBase64;

                              if (jsonDecode(defaultServices)
                                  .containsKey(value.toLowerCase())) {
                                // Get color and icon from json
                                color = Color(jsonDecode(defaultServices)[
                                    value.toLowerCase()]["color"]);
                                icon = jsonDecode(defaultServices)[
                                    value.toLowerCase()]["icon"];
                              }

                              keyStruct.value = KeyStruct(
                                  iconBase64: icon,
                                  key: keyStruct.value.key,
                                  service: value,
                                  color: color,
                                  description: keyStruct.value.description,
                                  interval: keyStruct.value.interval,
                                  eightDigits: keyStruct.value.eightDigits,
                                  algorithm: keyStruct.value.algorithm);
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: context.loc.service_name),
                          ),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: TextField(
                            onChanged: (value) {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: value,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: keyStruct.value.description,
                                  interval: keyStruct.value.interval,
                                  eightDigits: keyStruct.value.eightDigits,
                                  algorithm: keyStruct.value.algorithm);
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: context.loc.service_key),
                          ),
                        ),
                        const Divider(
                          height: 0,
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 0.0),
                          child: TextField(
                            onChanged: (value) {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: keyStruct.value.key,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: value,
                                  interval: keyStruct.value.interval,
                                  eightDigits: keyStruct.value.eightDigits,
                                  algorithm: keyStruct.value.algorithm);
                            },
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: context.loc.service_description),
                          ),
                        ),
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(context.loc.service_more_options),
                    ),
                    ListTile(
                        title: Text(context.loc.service_digits),
                        trailing: DropdownButton(
                          underline: Container(),
                          value: keyStruct.value.eightDigits,
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text("6"),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text("8"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: keyStruct.value.key,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: keyStruct.value.description,
                                  interval: keyStruct.value.interval,
                                  eightDigits: value ?? false,
                                  algorithm: keyStruct.value.algorithm);
                            });
                          },
                        )),
                    const Divider(
                      height: 0,
                    ),
                    ListTile(
                        title: Text(context.loc.service_algorithm),
                        trailing: DropdownButton(
                          underline: Container(),
                          value: keyStruct.value.algorithm,
                          items: const [
                            DropdownMenuItem(
                              value: OTPAlgorithm.SHA1,
                              child: Text("SHA1"),
                            ),
                            DropdownMenuItem(
                              value: OTPAlgorithm.SHA256,
                              child: Text("SHA256"),
                            ),
                            DropdownMenuItem(
                              value: OTPAlgorithm.SHA512,
                              child: Text("SHA512"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              keyStruct.value = KeyStruct(
                                  iconBase64: keyStruct.value.iconBase64,
                                  key: keyStruct.value.key,
                                  service: keyStruct.value.service,
                                  color: keyStruct.value.color,
                                  description: keyStruct.value.description,
                                  interval: keyStruct.value.interval,
                                  eightDigits: keyStruct.value.eightDigits,
                                  algorithm: value ?? OTPAlgorithm.SHA1);
                            });
                          },
                        )),
                    const Divider(
                      height: 0,
                    ),
                    ListTile(
                      title: Text(context.loc.service_interval),
                      trailing: DropdownButton(
                        underline: Container(),
                        value: keyStruct.value.interval,
                        items: const [
                          DropdownMenuItem(
                            value: 30,
                            child: Text("30"),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child: Text("60"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            keyStruct.value = KeyStruct(
                              iconBase64: keyStruct.value.iconBase64,
                              key: keyStruct.value.key,
                              service: keyStruct.value.service,
                              color: keyStruct.value.color,
                              description: keyStruct.value.description,
                              eightDigits: keyStruct.value.eightDigits,
                              interval: value ?? 30,
                              algorithm: keyStruct.value.algorithm,
                            );
                          });
                        },
                      ),
                    ),
                  ]),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        // Check if service name and key are not empty
                        if (keyStruct.value.service == "" ||
                            keyStruct.value.key == "") {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(context.loc.service_empty_error)));
                          return;
                        }
                        if (!KeyManagement()
                            .isValidBase32(keyStruct.value.key)) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(context.loc.service_invalid_key)));
                          return;
                        }
                        // Add service to database
                        if (await KeyManagement()
                            .addKeyManual(keyStruct.value, context)) {
                          if (context.mounted) {
                            currentScreen = 0;
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: Text(context.loc.add_service_name),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
