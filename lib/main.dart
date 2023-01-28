import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sekurity/homescreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sekurity/settings.dart';
import 'package:sekurity/tools/platformtools.dart';

import 'addService.dart';

void main() {
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
    doWhenWindowReady(() {
      appWindow.minSize = const Size(600, 450);
      appWindow.size = const Size(600, 450);
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
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

final buttonColors = WindowButtonColors(
    iconNormal: const Color.fromARGB(255, 175, 175, 175),
    mouseOver: const Color.fromARGB(255, 255, 255, 255),
    mouseDown: const Color.fromARGB(255, 66, 66, 66),
    iconMouseOver: const Color.fromARGB(255, 0, 0, 0),
    iconMouseDown: const Color.fromARGB(255, 0, 0, 0));

final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F), mouseDown: const Color(0xFFB71C1C), iconNormal: const Color.fromARGB(255, 175, 175, 175), iconMouseOver: Colors.white);

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinimizeWindowButton(colors: buttonColors),
          MaximizeWindowButton(colors: buttonColors),
          CloseWindowButton(colors: closeButtonColors),
        ],
      ),
    );
  }
}

var appTheme = ValueNotifier(0);
var bold = false;

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
