import 'dart:io';

import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:songtube_link_desktop/internal/http_server.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final autoStart = Platform.isLinux ? false : await launchAtStartup.isEnabled();
  LinkServer.initialize(autoStart);
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  LaunchAtStartup.instance.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );
  runApp(Main(autoStart: autoStart));
}

class Main extends StatefulWidget {
  const Main({
    required this.autoStart,
    super.key});
  final bool autoStart;
  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> with TrayListener{

  // Autostart status
  late bool autoStart = widget.autoStart;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    runTray(autoStart);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'exit_app') {
      exit(0);
    }
    if (menuItem.key == 'startup') {
      if (autoStart) {
        launchAtStartup.disable();
      } else {
        launchAtStartup.enable();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

void runTray(bool autoStart) async {
  final icon = Platform.isWindows
    ? 'assets/logo.ico'
    : 'assets/logo.png';
  await trayManager.setIcon(icon);
  List<MenuItem> items = [
    MenuItem(
      label: 'SongTube Link',
      icon: icon,
      disabled: true
    ),
    MenuItem.checkbox(
      label: linkServer != null ? 'connected' : 'disconnected',
      checked: linkServer != null,
      disabled: true,
      
    ),
    if (!Platform.isLinux)
    MenuItem.checkbox(
      key: 'startup',
      label: 'Launch at startup',
      checked: autoStart
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'exit_app',
      label: 'Exit App',
    ),
  ];
  await trayManager.setContextMenu(Menu(items: items));
}