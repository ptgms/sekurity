import 'package:context_menus/context_menus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:sekurity/views/authenticationfailed.dart';
import 'package:sekurity/views/homescreen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sekurity/views/import_export.dart';
import 'package:sekurity/views/settings.dart';
import 'package:sekurity/tools/keymanagement.dart';
import 'package:sekurity/tools/keys.dart';
import 'package:sekurity/tools/platformtools.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'views/add_service.dart';

void loadSettings() {
  SharedPreferences.getInstance().then((prefs) {
    appTheme.value = prefs.getInt('theme') ?? 0;
    //authentication = prefs.getInt('authentication') ?? 1;
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
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();
  const storage = FlutterSecureStorage();
  authentication = int.parse(await storage.read(key: 'authentication') ?? "0");
  debugPrint(
      "Startup verification is${authentication == 2 ? "" : " not"} enabled!");

  runApp(ChangeNotifierProvider(
      create: (context) => Keys(), child: const SekurityApp()));

  loadSettings();

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    if (isPlatformWindows()) {
      await WindowManager.instance.ensureInitialized();
      windowManager.waitUntilReadyToShow().then((_) async {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
        await windowManager.show();
      });
    }
    // Set the window title
    await windowManager.setTitle("Sekurity");
    await windowManager.setMinimumSize(const Size(400, 450));
    await windowManager.setMaximumSize(const Size(650, 900));
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
    try {
      final LocalAuthentication auth = LocalAuthentication();
        auth.isDeviceSupported().then((value) {
          authenticationSupported = value;});} catch (e) {}
    if (!appAuthenticationFailed.value && authentication == 2) {
      try {
        final LocalAuthentication auth = LocalAuthentication();
        auth.isDeviceSupported().then((value) {
          authenticationSupported = value;
          KeyManagement()
              .getSavedKeysFirstStart(context,
                  reason:
                      "You selected to be authenticated on startup. Please authenticate to continue.")
              .then((value) {
            if (value == -1) {
              setState(() {
                biometricCount++;
                if (biometricCount > 2) {
                  appAuthenticationFailed.value = true;
                }
              });
            }
          });
        });
      } catch (e) {
        KeyManagement()
            .getSavedKeys(context)
            .then((value) => debugPrint("Success!"));
      }
    } else if (!appAuthenticationFailed.value) {
      KeyManagement()
          .getSavedKeys(context)
          .then((value) => debugPrint("Success!"));
    }
    return ValueListenableBuilder(
      valueListenable: appTheme,
      builder: (_, mode, __) {
        return DynamicColorBuilder(
          builder: ((lightDynamic, darkDynamic) {
            var app = MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: const [
                Locale('en', ''),
                Locale('de', ''),
              ],
              debugShowCheckedModeBanner: false,
              title: 'Sekurity',
              initialRoute: '/',
              routes: {
                '/': (BuildContext context) => appAuthenticationFailed.value
                    ? const AuthenticationFailed()
                    : ContextMenuOverlay(
                        child: const HomePage(
                        title: "Sekurity",
                      )),
                '/addService': (BuildContext context) =>
                    appAuthenticationFailed.value
                        ? const AuthenticationFailed()
                        : const AddService(),
                '/settings': (BuildContext context) =>
                    appAuthenticationFailed.value
                        ? const AuthenticationFailed()
                        : const Settings(),
                '/importExport': (BuildContext context) =>
                    appAuthenticationFailed.value
                        ? const AuthenticationFailed()
                        : const ImportExport()
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
            return app;
          }),
        );
      },
    );
  }
}

var appTheme = ValueNotifier(0);
var authentication = 0;
var bold = false;
var time = 0;
var altProgress = false;
var forceAppbar = ValueNotifier(false);
var gradientBackground = true;
var biometricCount = 0;
var appAuthenticationFailed = ValueNotifier(false);

var authenticationSupported = false;

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
