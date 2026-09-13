import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/notifications/services/notification_provider.dart';
import 'routes.dart';

void main() {
  runApp(const MyApp());
}

/// MyApp
/// Root Widget of the Mobile Part Finder application.
/// Sets up state management (MultiProvider), GetMaterialApp with named routes, app theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: GetMaterialApp(
        title: 'Mobile Part Finder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.appTheme,
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.pages,
      ),
    );
  }
}
