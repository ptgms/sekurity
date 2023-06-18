import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sekurity/main.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:sekurity/tools/structtools.dart';
import 'package:url_launcher/url_launcher.dart';

void editDialog(KeyStruct keyToEdit, int index, BuildContext context) {
  var editedKey = keyToEdit;

  var serviceName = ValueNotifier(keyToEdit.service);
  var image = ValueNotifier(keyToEdit.iconBase64);
  var color = ValueNotifier(keyToEdit.color);
  showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          // Set shape for the dialog
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0),
          ),
          // Set padding for the dialog content
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: serviceName,
                      builder: (context, value, child) => Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                        child: Text(
                          context.loc.editing_dialog(value),
                          style: const TextStyle(fontSize: 24.0),
                        ),
                      ),
                    )
                  ],
                ),
                Center(
                  child: ValueListenableBuilder(
                    valueListenable: color,
                    builder: (context, value, child) => Card(
                        color: value,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ValueListenableBuilder(
                              valueListenable: image,
                              builder: (context, value, child) {
                                return value == ""
                                    ? Icon(Icons.key,
                                        size: 64.0, color: editedKey.color)
                                    : SizedBox(
                                        height: 64.0,
                                        width: 64.0,
                                        child: Image.memory(
                                          base64Decode(value),
                                          gaplessPlayback: true,
                                        ));
                              }),
                        )),
                  ),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                    onPressed: (() async {
                      if (isPlatformMobile()) {
                        // Image picker
                        final ImagePicker picker = ImagePicker();
                        final XFile? imagePicked =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (imagePicked != null) {
                          // Make image square and resize to 64x64
                          var imageBytes = StructTools().cropAndResizeImage(
                              base64Encode(await imagePicked.readAsBytes()));
                          image.value = imageBytes;
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
                          image.value = imageBytes;
                        } else {
                          // User canceled the picker
                        }
                      }
                    }),
                    child: Text(context.loc.service_icon),
                  ),
                  TextButton(
                    child: Text(context.loc.service_color),
                    onPressed: () {
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
                                  pickerColor: color.value,
                                  onColorChanged: (colorResp) {
                                    color.value = colorResp;
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(context.loc.dialog_close),
                                ),
                              ],
                            );
                          });
                    },
                  ),
                ]),
                Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                        child: TextField(
                          controller: TextEditingController()
                            ..text = keyToEdit.service,
                          onChanged: (value) async {
                            serviceName.value = value;
                            editedKey = KeyStruct(
                                iconBase64: editedKey.iconBase64,
                                key: editedKey.key,
                                service: value,
                                color: editedKey.color,
                                description: editedKey.description,
                                interval: editedKey.interval,
                                eightDigits: editedKey.eightDigits,
                                algorithm: editedKey.algorithm);
                          },
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: context.loc.service_name),
                        ),
                      ),
                      // divider uses dialog background

                      Padding(
                        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
                        child: TextField(
                          controller: TextEditingController()
                            ..text = keyToEdit.description,
                          onChanged: (value) async {
                            editedKey = KeyStruct(
                                iconBase64: editedKey.iconBase64,
                                key: editedKey.key,
                                service: editedKey.service,
                                color: editedKey.color,
                                description: value,
                                interval: editedKey.interval,
                                eightDigits: editedKey.eightDigits,
                                algorithm: editedKey.algorithm);
                          },
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: context.loc.service_description),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(context.loc.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        final itemModel =
                            Provider.of<Keys>(context, listen: false);
                        editedKey.color = color.value;
                        editedKey.iconBase64 = image.value;
                        editedKey.service = serviceName.value;
                        itemModel.items[index] = editedKey;
                        KeyManagement().saveKeys(itemModel.items);
                        itemModel.uiUpdate();
                        Navigator.of(context).pop();
                      },
                      child: Text(context.loc.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
}

void deleteDialog(KeyStruct keyToDelete, int index, BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(context.loc.home_delete_confirm(keyToDelete.service)),
      content: Text(
          context.loc.home_delete_confirm_description(keyToDelete.service)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.loc.home_delete_confirm_no),
        ),
        TextButton(
          onPressed: () async {
            final itemModel = Provider.of<Keys>(context, listen: false);
            // Delete key

            itemModel.removeItem(itemModel.items[index]);
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
}

void aboutDialog(BuildContext context) {
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
                      await launchUrl(Uri.parse("https://github.com/ptgms"));
                    },
                  ),
                )
              ],
            ),
          ]),
        ),
      ]);
}
