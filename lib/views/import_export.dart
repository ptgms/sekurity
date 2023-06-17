import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';

import 'homescreen.dart';
import '../main.dart';

class ImportExport extends StatefulWidget {
  const ImportExport({super.key});

  @override
  State<ImportExport> createState() => _ImportExportState();
}

class _ImportExportState extends State<ImportExport> {
  var unencrypted = false;
  @override
  Widget build(BuildContext context) {
    final itemModel = Provider.of<Keys>(context, listen: false);
    String password = "";

    var appBar = AppBar(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isPlatformMacos()
              ? CupertinoNavigationBarBackButton(
                  onPressed: () {
                    currentScreen = 0;
                    Navigator.of(context).pop();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                    currentScreen = 0;
                  },
                ),
        ],
      ),
      title: Text(context.loc.home_import_export),
    );

    return Scaffold(
      appBar: appBar,
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      labelText: context.loc.import_export_password),
                )
              : ListTile(
                  title: Text(context.loc.import_export_no_encryption_warning),
                  leading:
                      const Icon(Icons.warning_rounded, color: Colors.orange),
                ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  child: Text(context.loc.import_export_import),
                  onPressed: () async {
                    if (password == "") {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(context.loc.import_export_password_empty)));
                      return;
                    }
                    if (await KeyManagement().getDecryptedJson(password)) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(context.loc.import_export_import_success),
                          action: SnackBarAction(
                              label: context
                                  .loc.import_export_import_success_restart,
                              onPressed: exitApp),
                        ));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text(context.loc.import_export_import_error)));
                      }
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  child: Text(context.loc.import_export_export),
                  onPressed: () async {
                    if (itemModel.items.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.loc.import_export_no_keys)));
                      }
                      return;
                    }
                    if (password == "") {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                context.loc.import_export_password_empty)));
                      }
                      return;
                    }
                    await KeyManagement().getEncryptedJson(password, context);
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
                child: TextButton(
                  child: Text(context.loc.import_export_export_qr),
                  onPressed: () async {
                    if (itemModel.items.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.loc.import_export_no_keys)));
                      }
                      return;
                    }
                    // Show dialog
                    KeyManagement().parseTransferQR(context).then((value) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(context.loc.import_export_export_qr),
                              content: SizedBox(
                                  height: 300,
                                  width: 300,
                                  child: Center(child: value)),
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
