
import 'dart:developer' as developer;

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'gacha_service.dart';
import 'health_service.dart';
import 'task_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    CalendarScreen(),
    TaskScreen(),
    GachaScreen(),
    HealthScreen(),
    MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      // When tapping on the Health tab, refresh health data.
      context.read<HealthState>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'タスク',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'ゲーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'ヘルスケア',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'その他'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// A helper for handling calendar permissions securely.
Future<bool> _requestCalendarPermissions(
    DeviceCalendarPlugin deviceCalendarPlugin) async {
  final permissionsGranted = await deviceCalendarPlugin.hasPermissions();
  if (permissionsGranted.isSuccess && permissionsGranted.data == true) {
    return true;
  }

  final requestedPermissions = await deviceCalendarPlugin.requestPermissions();
  return requestedPermissions.isSuccess && requestedPermissions.data == true;
}

class CalendarState with ChangeNotifier {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  Calendar? _selectedCalendar;
  Calendar? get selectedCalendar => _selectedCalendar;

  List<Calendar> _calendars = [];
  List<Calendar> get calendars => _calendars;

  Map<DateTime, List<Event>> _events = {};
  Map<DateTime, List<Event>> get events => _events;

  List<Event> _selectedEvents = [];
  List<Event> get selectedEvents => _selectedEvents;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  CalendarFormat get calendarFormat => _calendarFormat;

  DateTime _focusedDay = DateTime.now();
  DateTime get focusedDay => _focusedDay;

  DateTime? _selectedDay;
  DateTime? get selectedDay => _selectedDay;

  CalendarState() {
    _selectedDay = _focusedDay;
    if (!kIsWeb) {
      _retrieveCalendars();
    }
  }

  Future<void> _retrieveCalendars() async {
    try {
      final hasPermission =
          await _requestCalendarPermissions(_deviceCalendarPlugin);
      if (!hasPermission) {
        developer.log('Calendar permission denied.', name: 'CalendarState');
        return;
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        _calendars = calendarsResult.data!;
        if (_calendars.isNotEmpty) {
          _selectedCalendar = _calendars.firstWhere(
            (cal) => cal.isReadOnly != true,
            orElse: () => _calendars.first,
          );
          await _fetchEvents();
        }
        notifyListeners();
      }
    } catch (e, s) {
      developer.log('Error retrieving calendars.',
          name: 'CalendarState', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchEvents([DateTime? start, DateTime? end]) async {
    if (_selectedCalendar == null || kIsWeb) return;

    final startDate =
        start ?? DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final endDate = end ?? DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

    try {
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        _selectedCalendar!.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        final newEvents = <DateTime, List<Event>>{};
        for (final event in eventsResult.data!) {
          if (event.start == null) continue;
          final day =
              DateTime(event.start!.year, event.start!.month, event.start!.day);
          newEvents[day] = [...newEvents[day] ?? [], event];
        }
        _events = newEvents;
        _selectedEvents = _getEventsForDay(_selectedDay!);
        notifyListeners();
      }
    } catch (e, s) {
      developer.log('Error fetching events.',
          name: 'CalendarState', error: e, stackTrace: s);
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
      notifyListeners();
    }
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    if (!kIsWeb) {
      _fetchEvents();
    }
  }

  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }

  void onCalendarChanged(String? calendarId) {
    if (calendarId != null) {
      _selectedCalendar =
          _calendars.firstWhere((cal) => cal.id == calendarId);
      _fetchEvents();
      notifyListeners();
    }
  }

  void setToday() {
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _selectedEvents = _getEventsForDay(_selectedDay!);
    notifyListeners();
  }

  Future<void> refreshEvents() async {
    await _fetchEvents();
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calendarState = Provider.of<CalendarState>(context);

    return Scaffold(
      appBar: AppBar(
        title: _buildCalendarDropdown(context, calendarState),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => calendarState.setToday(),
          ),
          _buildFormatButton(calendarState),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar<Event>(
              locale: 'ja_JP',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: calendarState.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(calendarState.selectedDay, day),
              calendarFormat: calendarState.calendarFormat,
              eventLoader: (day) =>
                  calendarState.events[DateTime(day.year, day.month, day.day)] ??
                  [],
              onDaySelected: calendarState.onDaySelected,
              onPageChanged: calendarState.onPageChanged,
              onFormatChanged: calendarState.onFormatChanged,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
            const Divider(),
            _buildEventList(context, calendarState),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateAndEditEvent(context, calendarState, null),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFormatButton(CalendarState calendarState) {
    return IconButton(
      icon: Icon(calendarState.calendarFormat == CalendarFormat.month
          ? Icons.view_week_outlined
          : Icons.calendar_month_outlined),
      onPressed: () => calendarState.onFormatChanged(
          calendarState.calendarFormat == CalendarFormat.month
              ? CalendarFormat.week
              : CalendarFormat.month),
    );
  }

  Widget _buildCalendarDropdown(
      BuildContext context, CalendarState calendarState) {
    if (kIsWeb || calendarState.calendars.isEmpty) {
      return const Text('カレンダー');
    }
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: calendarState.selectedCalendar?.id,
        onChanged: (String? newValue) =>
            calendarState.onCalendarChanged(newValue),
        items: calendarState.calendars
            .map<DropdownMenuItem<String>>((Calendar calendar) {
          return DropdownMenuItem<String>(
            value: calendar.id,
            child: Text(
              calendar.name ?? 'No Name',
              style: const TextStyle(color: Colors.black87),
            ),
          );
        }).toList(),
        selectedItemBuilder: (BuildContext context) {
          return calendarState.calendars.map<Widget>((Calendar cal) {
            return Center(
              child: Text(
                cal.name ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildEventList(BuildContext context, CalendarState calendarState) {
    if (kIsWeb) {
      return const Center(child: Text("カレンダー機能はWeb版では利用できません。"));
    }
    if (calendarState.selectedEvents.isEmpty) {
      return const Center(child: Text('今日の予定はありません'));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: calendarState.selectedEvents.length,
      itemBuilder: (context, index) {
        final event = calendarState.selectedEvents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(event.title ?? 'タイトルなし'),
            subtitle: Text(event.description ?? ''),
            leading: _buildEventLeading(event),
            onTap: () => _navigateAndEditEvent(context, calendarState, event),
          ),
        );
      },
    );
  }

  Widget _buildEventLeading(Event event) {
    if (event.allDay ?? false) {
      return const Icon(Icons.check_box_outline_blank, color: Colors.grey);
    }
    if (event.start == null || event.end == null) return const SizedBox();
    final format = DateFormat('HH:mm');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(format.format(event.start!.toLocal())),
        Text(format.format(event.end!.toLocal())),
      ],
    );
  }

  void _navigateAndEditEvent(
      BuildContext context, CalendarState calendarState, Event? event) async {
    if (calendarState.selectedCalendar == null || kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('この機能はWeb版では利用できません。')));
      return;
    }
    final result = await context.push('/event/edit', extra: {
      'event': event,
      'calendar': calendarState.selectedCalendar!,
      'selectedDate': calendarState.selectedDay,
    });

    if (result == true) {
      calendarState.refreshEvents();
    }
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('その他')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('通知設定'),
            subtitle: const Text('薬の服用時間などを通知します'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('この機能はWeb版では利用できません。')),
                );
                return;
              }
              context.push('/notification_setting');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('会員登録'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push('/register');
            },
          ),
        ],
      ),
    );
  }
}
