import 'package:flutter/material.dart';
import 'package:sekurity/components/menubar.dart';

class PlatformAppBar {
  String title = "";
  Widget? leading;
  List<Widget>? actions;
  List<SubMenuItem>? menuItems; // supplied for desktop shortcuts

  PlatformAppBar({required this.title, this.leading, this.actions, this.menuItems});
}