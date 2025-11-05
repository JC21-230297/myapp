
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for initialization
import 'package:myapp/gacha_service.dart';
import 'package:myapp/health_service.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/main.dart';
import 'package:myapp/notification_service.dart';
import 'package:myapp/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // This function is called once before all tests.
  setUpAll(() async {
    // Initialize SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    // Initialize date formatting for the 'ja_JP' locale.
    // This is required by the table_calendar package.
    await initializeDateFormatting('ja_JP');
  });

  testWidgets('App smoke test - initial screen and navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to wrap MyApp in the MultiProvider with all the necessary providers.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => GachaState()),
          ChangeNotifierProvider(create: (_) => HealthState()),
          ChangeNotifierProvider(create: (_) => CalendarState()), 
          Provider(create: (_) => NotificationService()),
        ],
        child: const MyApp(),
      ),
    );

    // Allow any initial async operations (like calendar loading) to complete.
    await tester.pumpAndSettle();

    // ---- 1. Verify the initial screen (CalendarScreen) is displayed correctly ----

    // Verify that the AppBar title is 'カレンダー'.
    // The title is inside a DropdownButton, so we find it as a descendant of AppBar.
    expect(find.descendant(of: find.byType(AppBar), matching: find.text('カレンダー')), findsOneWidget);

    // Verify that the "Today" button in the AppBar is present.
    expect(find.byIcon(Icons.today), findsOneWidget);

    // Verify that the calendar icon in the BottomNavigationBar is present.
    expect(find.byIcon(Icons.calendar_month), findsOneWidget);

    // ---- 2. Verify navigation to the Gacha screen ----

    // Tap the 'Gacha' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.games));
    await tester.pumpAndSettle(); // pumpAndSettle to wait for animations to finish

    // Verify that the AppBar title of the new screen is 'まめしばガチャ'.
    expect(find.text('まめしばガチャ'), findsOneWidget);

    // Verify that the 'ガチャを引く' button is present.
    expect(find.widgetWithText(ElevatedButton, 'ガチャを引く'), findsOneWidget);
  });
}
