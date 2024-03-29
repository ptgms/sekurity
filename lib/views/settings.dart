import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:sekurity/components/platform/platform_alert.dart';
import 'package:sekurity/components/platform/platform_appbar.dart';
import 'package:sekurity/components/platform/platform_scaffold.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'homescreen.dart';
import '../main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<void> saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("theme", appTheme.value);
    prefs.setInt("theme", appTheme.value);
    prefs.setBool("bold", bold);
    prefs.setBool("altProgress", altProgress);
    prefs.setBool("forceAppbar", forceAppbar.value);
    prefs.setBool("gradientBackground", gradientBackground);
    prefs.setInt("authentication", authentication);
    prefs.setBool("bigcards", bigCards);
    prefs.setInt("displayStyle", displayStyle.index);
    prefs.setBool("exitToTray", exitToTray);

    if (exitToTray) {
      await windowManager.setPreventClose(true);
    }
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
      debugPrint(e.toString());
      return false;
    }
  }

  void clearDialog(BuildContext context) {
    showPlatformDialog(context,
        title: Text(context.loc.home_clear),
        content: Text(context.loc.home_clear_confirm),
        buttons: [
          PlatformAlertButtons(
              text: context.loc.cancel,
              onPressed: () {
                Navigator.of(context).pop();
              }),
          PlatformAlertButtons(
              text: context.loc.home_clear,
              destructive: true,
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
              }),
        ]);
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

  void setEmergencyPasswordDialog() {
    TextEditingController textfield = TextEditingController();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    context.loc.settings_emergency_password,
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    context.loc.settings_emergency_password_description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  TextField(
                    controller: textfield,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: context.loc.settings_emergency_password,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () {
                      if (textfield.text.isNotEmpty) {
                        KeyManagement().setRestorePassword(textfield.text);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(context.loc.save),
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey dropdownTheme = GlobalKey();
    GlobalKey dropdownStyle = GlobalKey();
    GlobalKey dropdownAuth = GlobalKey();

    var appBar = PlatformAppBar(
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
      title: context.loc.settings,
    );

    var platform = PlatformUtils.detectPlatform(context);

    if (platform == DevicePlatform.web || platform == DevicePlatform.windows) {
      platform = DevicePlatform.android;
    }

    return PlatformScaffold(
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
              ),
              if (authenticationSupported)
                SettingsTile.navigation(
                  leading: const Icon(Icons.lock_rounded),
                  trailing: DropdownButton<int>(
                      alignment: AlignmentDirectional.centerEnd,
                      key: dropdownAuth,
                      icon: const Icon(Icons.chevron_right_outlined),
                      underline: Container(),
                      //iconSize: 0.0,
                      value: authentication,
                      onChanged: (value) async {
                        // lets authenticate the user before changing
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(context.loc.authentication_method),
                                actions: [
                                  TextButton(
                                    child: Text(context
                                        .loc.authentication_method_biometric),
                                    onPressed: () async {
                                      final LocalAuthentication auth =
                                          LocalAuthentication();
                                      if (authenticationSupported) {
                                        if (!await KeyManagement()
                                            .didSetRestorePassword()) {
                                          setEmergencyPasswordDialog();
                                          return;
                                        }
                                        try {
                                          var authenticated = await auth.authenticate(
                                              localizedReason: context.loc
                                                  .settings_authentication_strictness_verify,
                                              options:
                                                  const AuthenticationOptions(
                                                      stickyAuth: true));
                                          if (!authenticated) {
                                            setState(() {
                                              authentication = authentication;
                                            });
                                            return;
                                          } else {
                                            const storage =
                                                FlutterSecureStorage();
                                            setState(() async {
                                              authentication = value ?? 1;
                                              await storage.write(
                                                  key: 'authentication',
                                                  value: authentication
                                                      .toString());
                                            });
                                            saveSettings();
                                            if (context.mounted)
                                              Navigator.of(context).pop();
                                          }
                                        } catch (e) {
                                          const storage =
                                              FlutterSecureStorage();
                                          setState(() {
                                            authentication = value ?? 1;
                                          });
                                          await storage.write(
                                              key: 'authentication',
                                              value: authentication.toString());
                                          saveSettings();
                                          if (context.mounted)
                                            Navigator.of(context).pop();
                                        }
                                      }
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                        context.loc.use_emergency_password),
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(context
                                                  .loc.use_emergency_password),
                                              content: TextField(
                                                obscureText: true,
                                                onChanged: (password) async {
                                                  if (await KeyManagement()
                                                      .verifyRestorePassword(
                                                          password)) {
                                                    const storage =
                                                        FlutterSecureStorage();
                                                    setState(() {
                                                      authentication =
                                                          value ?? 1;
                                                    });
                                                    await storage.write(
                                                        key: 'authentication',
                                                        value: authentication
                                                            .toString());
                                                    saveSettings();
                                                    if (context.mounted)
                                                      Navigator.of(context)
                                                          .pop();
                                                  }
                                                },
                                              ),
                                            );
                                          });
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                              context
                                  .loc.settings_authentication_strictness_never,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                              context.loc
                                  .settings_authentication_strictness_exports,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(context
                              .loc.settings_authentication_strictness_always),
                        )
                      ]),
                  title: Text(context.loc.settings_authentication_strictness),
                  description: Text(context
                      .loc.settings_authentication_strictness_description),
                  onPressed: (context) {
                    openDropdown(dropdownAuth);
                  },
                ),
              if (!isPlatformMobile())
                SettingsTile.switchTile(
                  leading: const Icon(Icons.visibility_off_rounded),
                  initialValue: exitToTray,
                  onToggle: (value) {
                    setState(() {
                      exitToTray = value;
                    });
                    saveSettings();
                  },
                  title: Text(context.loc.settings_exit_to_tray),
                  description:
                      Text(context.loc.settings_exit_to_tray_description),
                )
            ]),
            SettingsSection(
              title: Text(context.loc.settings_appearance),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.color_lens_outlined),
                  trailing: DropdownButton<int>(
                      alignment: AlignmentDirectional.centerEnd,
                      key: dropdownTheme,
                      icon: const Icon(Icons.chevron_right_outlined),
                      underline: Container(),
                      //iconSize: 0.0,
                      value: appTheme.value,
                      onChanged: (value) {
                        setState(() {
                          appTheme.value = value ?? 0;
                        });
                        saveSettings();
                      },
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(context.loc.settings_theme_system,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text(context.loc.settings_theme_light,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(context.loc.settings_theme_dark),
                        )
                      ]),
                  title: Text(context.loc.settings_theme),
                  onPressed: (context) {
                    openDropdown(dropdownTheme);
                  },
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.list_alt_rounded),
                  trailing: DropdownButton<AppStyle>(
                      alignment: AlignmentDirectional.centerEnd,
                      key: dropdownStyle,
                      icon: const Icon(Icons.chevron_right_outlined),
                      underline: Container(),
                      //iconSize: 0.0,
                      value: displayStyle,
                      onChanged: (value) {
                        setState(() {
                          displayStyle = value ?? AppStyle.minimalistic;
                        });
                        final itemModel =
                            Provider.of<Keys>(context, listen: false);
                        itemModel.uiUpdate();
                        saveSettings();
                      },
                      items: [
                        DropdownMenuItem(
                          value: AppStyle.minimalistic,
                          child: Text(
                              context.loc.settings_view_style_minimalistic,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: AppStyle.cards,
                          child: Text(context.loc.settings_view_style_cards,
                              textAlign: TextAlign.center),
                        ),
                        DropdownMenuItem(
                          value: AppStyle.habbit,
                          child: Text(context.loc.settings_view_style_habbit),
                        )
                      ]),
                  title: Text(context.loc.settings_view_style),
                  description:
                      Text(context.loc.settings_view_style_description),
                  onPressed: (context) {
                    openDropdown(dropdownStyle);
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
                if (!isPlatformMobile() && !isPlatformWindows())
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
                if (displayStyle == AppStyle.cards) SettingsTile.switchTile(
                    initialValue: gradientBackground,
                    onToggle: (value) {
                      final itemModel =
                          Provider.of<Keys>(context, listen: false);
                      setState(() {
                        gradientBackground = value;
                      });
                      itemModel.uiUpdate();
                      saveSettings();
                    },
                    title: Text(context.loc.settings_gradient),
                    description:
                        Text(context.loc.settings_gradient_description),
                    leading: const Icon(Icons.gradient)),
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
                  if (displayStyle == AppStyle.cards) SettingsTile.switchTile(
                    initialValue: bigCards,
                    leading: const Icon(Icons.crop_square_rounded),
                    onToggle: (value) {
                      setState(() {
                        bigCards = value;
                      });
                      final itemModel =
                          Provider.of<Keys>(context, listen: false);
                      itemModel.uiUpdate();
                      saveSettings();
                    },
                    title: Text(context.loc.settings_big_cards),
                    description:
                        Text(context.loc.settings_big_cards_description),
                  )
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
                ),
                if (authenticationSupported)
                  SettingsTile.navigation(
                    enabled: (authentication == 0),
                    title: Text(context.loc.settings_emergency_password_reset),
                    description: Text(context
                        .loc.settings_emergency_password_reset_description),
                    leading: const Icon(Icons.key_off_rounded),
                    onPressed: (context) {
                      if (authentication != 0) {
                        return;
                      }
                      KeyManagement().setRestorePassword("").then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(context
                              .loc.settings_emergency_password_reset_success),
                          duration: const Duration(seconds: 2),
                        ));
                      });
                    },
                  ),
              ],
            )
          ],
        ));
  }
}
