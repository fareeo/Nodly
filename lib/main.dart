import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'screens/home_screen.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise services
  final settings = SettingsService();
  await settings.init();
  await NotificationService().init();

  // Schedule notifications on launch (refreshes content for today)
  if (settings.notificationsEnabled) {
    NotificationService().scheduleReminder();
  }

  runApp(NodlyApp(settings: settings));
}

class NodlyApp extends StatelessWidget {
  const NodlyApp({super.key, required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return MaterialApp(
              title: 'Nodly',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.buildTheme(
                themeName: settings.themeName,
                brightness: Brightness.light,
                accentColor: settings.accentColor,
                fontFamily: settings.fontFamily,
                fontSizeScale: settings.fontSizeScale,
                dynamicScheme: lightDynamic,
              ),
              darkTheme: AppTheme.buildTheme(
                themeName: settings.themeName,
                brightness: Brightness.dark,
                accentColor: settings.accentColor,
                fontFamily: settings.fontFamily,
                fontSizeScale: settings.fontSizeScale,
                dynamicScheme: darkDynamic ?? lightDynamic,
              ),
              themeMode: settings.themeMode,
              // Global font-size scaling via textScaler
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.fontSizeScale),
                  ),
                  child: child!,
                );
              },
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
