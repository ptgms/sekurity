import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sekurity/homescreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sekurity/import_export.dart';
import 'package:sekurity/settings.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:window_size/window_size.dart';

import 'addService.dart';

Future<void> main() async {
  runApp(const SekurityApp());

  const storage = FlutterSecureStorage();
  storage.read(key: "theme").then((value) {
    if (value != null) {
      appTheme.value = value == "0"
          ? 0
          : value == "1"
              ? 1
              : 2;
    }
  });
  storage.read(key: "bold").then((value) {
    if (value != null) {
      bold = value == "true";
    }
  });

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    // Set the window title
    setWindowTitle('Sekurity');
    setWindowMinSize(const Size(400, 450));
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
    return ValueListenableBuilder(
      valueListenable: appTheme,
      builder: (_, mode, __) {
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
            '/': (BuildContext context) => const HomePage(title: 'Sekurity'),
            '/addService': (BuildContext context) => const AddService(),
            '/settings': (BuildContext context) => const Settings(),
            '/importExport': (BuildContext context) => const ImportExport(),
          },
          themeMode: (mode == 0)
              ? ThemeMode.system
              : (mode == 1)
                  ? ThemeMode.light
                  : ThemeMode.dark,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(
            useMaterial3: true,
          ),
        );
      },
    );
  }
}

var appTheme = ValueNotifier(0);
var bold = false;

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
