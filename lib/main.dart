import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    bigCards = prefs.getBool('bigcards') ?? false;
    forceAppbar.value = prefs.getBool('forceAppbar') ?? false;
    gradientBackground = prefs.getBool('gradientBackground') ?? true;
    displayStyle = AppStyle.values[prefs.getInt('displayStyle') ?? 0];
    exitToTray = prefs.getBool('exitToTray') ?? false;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!isPlatformMobile()) {
    await Window.initialize();
  }

  if (isPlatformAndroid()) {
    //Setting SysemUIOverlay
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark));

//Setting SystmeUIMode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: []);
  }

  const storage = FlutterSecureStorage();
  authentication = int.parse(await storage.read(key: 'authentication') ?? "0");
  debugPrint(
      "Startup verification is${authentication == 2 ? "" : " not"} enabled!");

  runApp(ChangeNotifierProvider(
      create: (context) => Keys(), child: const SekurityApp()));

  loadSettings();

  if (isPlatformMacos() || isPlatformLinux() || isPlatformWindows()) {
    await WindowManager.instance.ensureInitialized();
    if (isPlatformWindows()) {
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
    await windowManager.setMaximizable(false);

    if (exitToTray) {
      await windowManager.setPreventClose(true);
    }
  }
}

class SekurityApp extends StatefulWidget {
  const SekurityApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return SekurityState();
  }
}

class SekurityState extends State<SekurityApp> with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      AppWindow().hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (isPlatformWindows() || isPlatformAndroid() || isPlatformIOS()) {
        final LocalAuthentication auth = LocalAuthentication();
        auth.isDeviceSupported().then((value) {
          authenticationSupported = value;
        });
      }
      // ignore: empty_catches
    } catch (e) {}
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
                    : const HomePage(
                        title: "Sekurity",
                      ),
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
var bigCards = false;

// style enums
enum AppStyle { minimalistic, cards, habbit }

var displayStyle = AppStyle.minimalistic;

var exitToTray = false;

var authenticationSupported = false;

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
