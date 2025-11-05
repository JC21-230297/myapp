
import 'package:device_calendar/device_calendar.dart';
import 'package:go_router/go_router.dart';

import 'event_edit_screen.dart';
import 'goal_setting_screen.dart';
import 'home_screen.dart';
import 'memo_screen.dart';
import 'notification_setting_screen.dart';
import 'register_screen.dart';
import 'weekly_report_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyHomePage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/memo',
      builder: (context, state) {
        final DateTime? selectedDate = state.extra as DateTime?;
        return MemoScreen(selectedDate: selectedDate);
      },
    ),
    GoRoute(
      path: '/weekly_report',
      builder: (context, state) => const WeeklyReportScreen(),
    ),
    GoRoute(
      path: '/notification_setting',
      builder: (context, state) => const NotificationSettingScreen(),
    ),
    GoRoute(
      path: '/goal_setting',
      builder: (context, state) => const GoalSettingScreen(),
    ),
    GoRoute(
      path: '/event/edit',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
        return EventEditScreen(
          event: args['event'] as Event?,
          calendar: args['calendar'] as Calendar,
          selectedDate: args['selectedDate'] as DateTime?,
        );
      },
    ),
  ],
);
