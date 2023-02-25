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
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  LaunchAtStartup.instance.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );
  final autoStart = await launchAtStartup.isEnabled();
  LinkServer.initialize(autoStart);
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

class _MainState extends State<Main> with TrayListener, WindowListener {

  // Autostart status
  late bool autoStart = widget.autoStart;

  @override
  void initState() {
    TrayManager.instance.addListener(this);
    windowManager.addListener(this);
    super.initState();
    runTray(autoStart);
  }

  @override
  void dispose() {
    TrayManager.instance.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
    // do something
  }

  @override
  void onTrayIconMouseDown() {
    TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    TrayManager.instance.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'exit_app') {
      exit(0);
    }
    if (menuItem.key == 'startup') {
      if (autoStart) {
        await launchAtStartup.disable();
      } else {
        await launchAtStartup.enable();
      }
      autoStart = await launchAtStartup.isEnabled();
      runTray(autoStart);
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
      key: 'title',
      label: 'SongTube Link Server',
      icon: icon,
      disabled: true
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
  await trayManager.setToolTip('SongTube Link Server');
  await trayManager.setContextMenu(Menu(items: items));
}