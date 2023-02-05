import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:settings_ui/settings_ui.dart';

import 'homescreen.dart';
import 'main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<void> saveSettings() async {
    const storage = FlutterSecureStorage();
    storage.write(key: "theme", value: appTheme.toString());
    storage.write(key: "bold", value: bold ? "true" : "false");

    return;
  }

  void openDropdown(GlobalKey toOpen) {
    toOpen.currentContext?.visitChildElements((element) {
      if (element.widget is Semantics) {
        element.visitChildElements((element) {
          if (element.widget is Actions) {
            element.visitChildElements((element) {
              Actions.invoke(element, const ActivateIntent());
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var themes = ["System", "Light", "Dark"];

    GlobalKey _dropdownTheme = GlobalKey();

    var appBar = AppBar(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          (isPlatformMacos()) ? const SizedBox(width: 40) : Container(),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
              currentScreen = 0;
            },
          ),
        ],
      ),
      title: Text(context.loc.settings),
    );

    var platform = PlatformUtils.detectPlatform(context);

    if (platform == DevicePlatform.web || platform == DevicePlatform.windows) platform = DevicePlatform.android;

    return Scaffold(
        appBar: appBar,
        body: SettingsList(
          platform: platform,
          sections: [
            SettingsSection(
              title: Text(context.loc.settings_apperance),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.color_lens_outlined),
                  trailing: DropdownButton<String>(
                      alignment: AlignmentDirectional.centerEnd,
                      key: _dropdownTheme,
                      icon: const Icon(Icons.chevron_right_outlined),
                      underline: Container(),
                      //iconSize: 0.0,
                      value: themes[appTheme.value],
                      onChanged: (value) {
                        switch (value) {
                          case "System":
                            setState(() {
                              appTheme.value = 0;
                            });
                            break;
                          case "Light":
                            setState(() {
                              appTheme.value = 1;
                            });
                            break;
                          case "Dark":
                            setState(() {
                              appTheme.value = 2;
                            });
                            break;
                          default:
                        }
                        saveSettings();
                      },
                      items: [
                        DropdownMenuItem(
                          value: "System",
                          child: Text(context.loc.settings_theme_system, textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: "Light",
                          child: Text(context.loc.settings_theme_light, textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: "Dark",
                          child: Text(context.loc.settings_theme_dark),
                        )
                      ]),
                  title: Text(context.loc.settings_theme),
                  onPressed: (context) {
                    openDropdown(_dropdownTheme);
                  },
                ),
              ],
            ),
            SettingsSection(title: Text(context.loc.settings_accessibility), tiles: [
              SettingsTile.switchTile(
                title: Text(context.loc.settings_accessibility_font_style),
                description: Text(bold ? context.loc.settings_accessibility_font_style_large : context.loc.settings_accessibility_font_style_normal),
                leading: const Icon(Icons.text_fields),
                onToggle: (value) {
                  setState(() {
                    bold = value;
                    KeyManagement().version.value++;
                  });
                  saveSettings();
                },
                initialValue: bold,
              ),
            ]),
            SettingsSection(
              title: Text(context.loc.settings_reset),
              tiles: [
                SettingsTile.navigation(
                  title: Text(context.loc.home_clear),
                  leading: const Icon(Icons.delete_forever_rounded),
                  onPressed: (context) {
                    KeyManagement().saveKeys(List<KeyStruct>.empty());
                    KeyManagement().version = ValueNotifier(KeyManagement().version.value + 1);
                  },
                )
              ],
            )
          ],
        ));
  }
}
