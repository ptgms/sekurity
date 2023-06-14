import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homescreen.dart';
import 'main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<void> saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("theme", appTheme.value);
    prefs.setBool("bold", bold);
    prefs.setBool("altProgress", altProgress);
    prefs.setBool("forceAppbar", forceAppbar.value);
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

  Future<bool> getNTPTime(String server) async {
    try {
      int timeLookup = await NTP.getNtpOffset(
          localTime: DateTime.now(), lookUpAddress: server);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setInt("time", time);
      time = timeLookup;
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearDialog(BuildContext context) {
    var dialog = AlertDialog(
      title: Text(context.loc.home_clear),
      content: Text(context.loc.home_clear_confirm),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.loc.cancel),
        ),
        TextButton(
          onPressed: () {
            final itemModel = Provider.of<Keys>(context, listen: false);
            var backup = itemModel.items;
            itemModel.clear();
            KeyManagement().saveKeys([]);
            // show snackbar to undo
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(context.loc.home_clear_success),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: context.loc.undo,
                onPressed: () {
                  itemModel.clear();
                  for (var i = 0; i < backup.length; i++) {
                    itemModel.addItem(backup[i]);
                  }
                  KeyManagement().saveKeys(backup);
                },
              ),
            ));
            Navigator.of(context).pop();
          },
          child: Text(context.loc.home_clear),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => dialog);
  }

  void chooseNTPDialog(BuildContext context) {
    // let user choose the ntp server
    var dialog = AlertDialog(
      title: Text(context.loc.settings_sync_choose),
      content: Text(context.loc.settings_sync_choose_description),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.loc.cancel),
        ),
        TextButton(
          onPressed: () {
            // get the time from the server
            getNTPTime("time.google.com").then((value) {
              // show snackbar
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: value
                    ? Text(context.loc.settings_sync_success)
                    : Text(context.loc.settings_sync_error),
                duration: const Duration(seconds: 2),
              ));
              Navigator.of(context).pop();
            });
          },
          child: Text(context.loc.settings_sync_choose_google),
        ),
        TextButton(
          onPressed: () {
            // get the time from the server
            getNTPTime("pool.ntp.org").then((value) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: value
                    ? Text(context.loc.settings_sync_success)
                    : Text(context.loc.settings_sync_error),
                duration: const Duration(seconds: 2),
              ));
              Navigator.of(context).pop();
            });
          },
          child: Text(context.loc.settings_sync_choose_ntppool),
        ),
        TextButton(
          onPressed: () {
            // get the time from the server
            getNTPTime("time.apple.com").then((value) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: value
                    ? Text(context.loc.settings_sync_success)
                    : Text(context.loc.settings_sync_error),
                duration: const Duration(seconds: 2),
              ));
              Navigator.of(context).pop();
            });
          },
          child: Text(context.loc.settings_sync_choose_apple),
        ),
      ],
    );
    showDialog(context: context, builder: (context) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    var themes = ["System", "Light", "Dark"];

    GlobalKey dropdownTheme = GlobalKey();

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
      title: Text(context.loc.settings),
    );

    var platform = PlatformUtils.detectPlatform(context);

    if (platform == DevicePlatform.web || platform == DevicePlatform.windows) {
      platform = DevicePlatform.android;
    }

    return Scaffold(
        appBar: appBar,
        body: SettingsList(
          platform: platform,
          sections: [
            SettingsSection(title: Text(context.loc.settings_system), tiles: [
              SettingsTile.navigation(
                title: Text(context.loc.settings_sync_time),
                description: Text(context.loc.settings_sync_time_description),
                leading: const Icon(Icons.sync_rounded),
                onPressed: (context) {
                  chooseNTPDialog(context);
                },
              )
            ]),
            SettingsSection(
              title: Text(context.loc.settings_apperance),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.color_lens_outlined),
                  trailing: DropdownButton<String>(
                      alignment: AlignmentDirectional.centerEnd,
                      key: dropdownTheme,
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
                          child: Text(context.loc.settings_theme_system,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: "Light",
                          child: Text(context.loc.settings_theme_light,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: "Dark",
                          child: Text(context.loc.settings_theme_dark),
                        )
                      ]),
                  title: Text(context.loc.settings_theme),
                  onPressed: (context) {
                    openDropdown(dropdownTheme);
                  },
                ),
                SettingsTile.switchTile(
                  leading: const Icon(Icons.hourglass_bottom_rounded),
                  initialValue: altProgress,
                  onToggle: (value) {
                    final itemModel = Provider.of<Keys>(context, listen: false);
                    setState(() {
                      altProgress = value;
                    });
                    itemModel.uiUpdate();
                    saveSettings();
                  },
                  title: Text(context.loc.settings_alt_progress),
                  description:
                      Text(context.loc.settings_alt_progress_description),
                ),
                if (!isPlatformMobile())
                  SettingsTile.switchTile(
                    leading: const Icon(Icons.menu),
                    initialValue: forceAppbar.value,
                    onToggle: (value) {
                      setState(() {
                        forceAppbar.value = value;
                      });
                      // show snackbar for restart
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.loc.restart_prompt),
                        action: SnackBarAction(
                          label: context.loc.restart,
                          onPressed: () {
                            exitApp();
                          },
                        ),
                        duration: const Duration(seconds: 2),
                      ));
                      saveSettings();
                    },
                    title: Text(context.loc.settings_menubar_replacement),
                    description: Text(
                        context.loc.settings_menubar_replacement_description),
                  ),
              ],
            ),
            SettingsSection(
                title: Text(context.loc.settings_accessibility),
                tiles: [
                  SettingsTile.switchTile(
                    title: Text(context.loc.settings_accessibility_font_style),
                    description: Text(bold
                        ? context.loc.settings_accessibility_font_style_large
                        : context.loc.settings_accessibility_font_style_normal),
                    leading: const Icon(Icons.text_fields),
                    onToggle: (value) {
                      setState(() {
                        bold = value;
                      });
                      final itemModel =
                          Provider.of<Keys>(context, listen: false);
                      itemModel.uiUpdate();
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
                    clearDialog(context);
                  },
                )
              ],
            )
          ],
        ));
  }
}
