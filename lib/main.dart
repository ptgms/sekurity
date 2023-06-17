import 'dart:convert';

import 'package:context_menus/context_menus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sekurity/tools/decode_migration.dart';
import 'package:sekurity/views/homescreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sekurity/views/import_export.dart';
import 'package:sekurity/views/settings.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_size/window_size.dart';

import 'views/add_service.dart';

void loadSettings() {
  SharedPreferences.getInstance().then((prefs) {
    appTheme.value = prefs.getInt('theme') ?? 0;
    bold = prefs.getBool('bold') ?? false;
    time = prefs.getInt('time') ?? 0;
    if (prefs.getBool('hidden') ?? false) {
      AppWindow().hide();
    }
    altProgress = prefs.getBool('altProgress') ?? false;
    forceAppbar.value = prefs.getBool('forceAppbar') ?? false;
    gradientBackground = prefs.getBool('gradientBackground') ?? true;
  });
}

Future<void> main() async {
  runApp(ChangeNotifierProvider(
      create: (context) => Keys(), child: const SekurityApp()));

  loadSettings();

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    // Set the window title
    setWindowTitle('Sekurity');
    setWindowMinSize(const Size(400, 450));
    setWindowMaxSize(const Size(650, 900));
  }
}

class SekurityApp extends StatefulWidget {
  const SekurityApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return SekurityState();
  }
}

class SekurityState extends State<SekurityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    KeyManagement()
        .getSavedKeys(context)
        .then((value) => debugPrint("Success!"));
    return ValueListenableBuilder(
      valueListenable: appTheme,
      builder: (_, mode, __) {
        return DynamicColorBuilder(builder: ((lightDynamic, darkDynamic) {
          return MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [
            Locale('en', ''),
            Locale('de', ''),
          ],
          debugShowCheckedModeBanner: false,
          title: 'Sekurity',
          initialRoute: '/',
          routes: {
            '/': (BuildContext context) => ContextMenuOverlay(
                    child: const HomePage(
                  title: "Sekurity",
                )),
            '/addService': (BuildContext context) => const AddService(),
            '/settings': (BuildContext context) => const Settings(),
            '/importExport': (BuildContext context) => const ImportExport()
          },
          themeMode: (mode == 0)
              ? ThemeMode.system
              : (mode == 1)
                  ? ThemeMode.light
                  : ThemeMode.dark,
          theme: ThemeData(
            //primarySwatch: Colors.blue,
            colorScheme: lightDynamic,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: darkDynamic,
            useMaterial3: true,
          ),
        );
        }));
      },
    );
  }
}

var appTheme = ValueNotifier(0);
var bold = false;
var time = 0;
var altProgress = false;
var forceAppbar = ValueNotifier(false);
var gradientBackground = true;

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
