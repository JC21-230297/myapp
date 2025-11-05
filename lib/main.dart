
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'gacha_service.dart';
import 'health_service.dart';
import 'home_screen.dart';
import 'notification_service.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    final NotificationService notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
  }

  await initializeDateFormatting('ja_JP', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalendarState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HealthState()),
        ChangeNotifierProvider(create: (_) => GachaState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Calendar & Health App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.notoSansJpTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal, brightness: Brightness.dark),
      ),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
    );
  }
}
