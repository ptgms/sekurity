import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/platformtools.dart';

import 'homescreen.dart';
import 'main.dart';

class ImportExport extends StatefulWidget {
  const ImportExport({super.key});

  @override
  State<ImportExport> createState() => _ImportExportState();
}

class _ImportExportState extends State<ImportExport> {
  var unencrypted = false;
  @override
  Widget build(BuildContext context) {
    String password = "";

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
      title: Text(context.loc.home_import_export),
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: (isPlatformWindows() || isPlatformLinux() || isPlatformMacos()) ? MoveWindow(child: appBar) : appBar,
      ),
      body: ListView(children: [
        ListTile(
          title: Text(context.loc.import_export_description),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: !unencrypted
              ? TextField(
                  onChanged: (value) {
                    password = value.toString();
                  },
                  decoration: InputDecoration(
                      icon: const Icon(Icons.password_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      labelText: context.loc.import_export_password),
                )
              : ListTile(
                  title: Text(context.loc.import_export_no_encryption_warning),
                  leading: const Icon(Icons.warning_rounded, color: Colors.orange),
                ),
        ),
        /*Padding(
          padding: const EdgeInsets.all(8.0),
          child: CheckboxListTile(
            title: Text(context.loc.import_export_no_encryption),
            subtitle: Text(context.loc.import_export_no_encryption_description),
            value: unencrypted,
            onChanged: (bool? value) {
              // Confirmation dialog
              if (value == true) {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(context.loc.import_export_no_encryption_dialog),
                        content: Text(context.loc.import_export_no_encryption_dialog_description),
                        actions: [
                          TextButton(
                            child: Text(context.loc.import_export_no_encryption_dialog_no),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text(context.loc.import_export_no_encryption_dialog_yes),
                            onPressed: () {
                              unencrypted = true;
                              setState(() {
                                unencrypted = true;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    });
              } else {
                setState(() {
                  unencrypted = false;
                });
              }
            },
          ),
        ),*/
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PlatformTextButton(
                  child: Text(context.loc.import_export_import),
                  onPressed: () {
                    if (password == "") {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.import_export_password_empty)));
                      return;
                    }
                    KeyManagement().getDecryptedJson(password);
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PlatformTextButton(
                  child: Text(context.loc.import_export_export),
                  onPressed: () async {
                    if (password == "") {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.loc.import_export_password_empty)));
                      return;
                    }
                    await KeyManagement().getEncryptedJson(password);
                  },
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Divider(),
        ),
        ListTile(
          title: Text(context.loc.qr_transfer_notice),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PlatformTextButton(
                  child: Text(context.loc.import_export_export_qr),
                  onPressed: () async {
                    // Show dialog
                    KeyManagement().parseTransferQR().then((value) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(context.loc.import_export_export_qr),
                              content: SizedBox(height: 200, width: 200, child: Center(child: value)),
                              actions: [
                                TextButton(
                                  child: Text(context.loc.dialog_close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          });
                    });
                  },
                ),
              ),
            ),
          ],
        )
      ]),
    );
  }
}
