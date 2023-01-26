import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sekurity/homescreen.dart';
import 'package:window_size/window_size.dart';

import 'addService.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Sekurity');
    setWindowMinSize(const Size(455, 300));
    setWindowMaxSize(Size.infinite);
  }

  runApp(const SekurityApp());
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sekurity',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(title: 'Sekurity'),
        '/addService': (context) => const AddService(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
    );
  }
}
