import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'features/widget/widget_window.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final controller = await WindowController.fromCurrentEngine();
  if (controller.arguments == 'movia-widget') {
    await configureWidgetWindow();
    runApp(const ProviderScope(child: WidgetApp()));
    return;
  }
  await windowManager.ensureInitialized();
  unawaited(
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(1000, 680),
        center: true,
        title: 'Movia',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
  );
  await controller.setWindowMethodHandler(handleMainWindowMessage);
  runApp(const ProviderScope(child: MoviaApp()));
  if ((await SharedPreferences.getInstance()).getBool('startWidgetWithMovia') ==
      true) {
    unawaited(WidgetWindowService.open());
  }
}
