
import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_calendar/device_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class HealthState with ChangeNotifier {
  final Health _health = Health();
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  int _steps = 0;
  int get steps => _steps;

  double _sleepHours = 0.0;
  double get sleepHours => _sleepHours;

  int _stepGoal = 10000;
  int get stepGoal => _stepGoal;

  List<Event> _todaysEvents = [];
  List<Event> get todaysEvents => _todaysEvents;

  StreamSubscription<StepCount>? _stepCountSubscription;

  List<BarChartGroupData> _sleepData = [];
  List<BarChartGroupData> get sleepData => _sleepData;
  List<BarChartGroupData> _stepsData = [];
  List<BarChartGroupData> get stepsData => _stepsData;

  HealthState() {
    init();
  }

  Future<void> init() async {
    await _loadStepGoal();
    if (!kIsWeb) {
      _initPedometer();
      await _fetchHealthData();
      await _retrieveTodaysEvents();
      await _fetchWeeklyHealthData();
    }
    notifyListeners();
  }

  void _initPedometer() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = Pedometer.stepCountStream.listen((stepCount) {
      _steps = stepCount.steps;
      notifyListeners();
    });
  }

  Future<void> _loadStepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    _stepGoal = prefs.getInt('stepGoal') ?? 10000;
  }

  Future<void> _fetchHealthData() async {
    final types = [HealthDataType.SLEEP_IN_BED];
    if (await _health.requestAuthorization(types)) {
      try {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
          startTime: yesterday,
          endTime: now,
          types: types,
        );
        double totalSleep = healthData.fold(
            0,
            (sum, data) =>
                sum + (data.value as NumericHealthValue).numericValue.toDouble());
        _sleepHours = totalSleep / 60;
      } catch (e, s) {
        developer.log('Error fetching health data.',
            name: 'HealthState', error: e, stackTrace: s);
      }
    }
  }

  Future<void> _retrieveTodaysEvents() async {
    if (!await _requestCalendarPermissions(_deviceCalendarPlugin)) {
      developer.log("Calendar permission denied for today's events.",
          name: 'HealthState');
      return;
    }
    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      if (calendarsResult.isSuccess && calendarsResult.data?.isNotEmpty == true) {
        final calendar = calendarsResult.data!.first;
        final now = DateTime.now();
        final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
          calendar.id!,
          RetrieveEventsParams(
            startDate: DateTime(now.year, now.month, now.day),
            endDate: DateTime(now.year, now.month, now.day, 23, 59),
          ),
        );
        if (eventsResult.isSuccess) {
          _todaysEvents = eventsResult.data ?? [];
        }
      }
    } catch (e, s) {
      developer.log("Error retrieving today's events.",
          name: 'HealthState', error: e, stackTrace: s);
    }
  }

  Future<void> _fetchWeeklyHealthData() async {
    final types = [HealthDataType.SLEEP_IN_BED, HealthDataType.STEPS];
    if (await _health.requestAuthorization(types)) {
      try {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
          startTime: sevenDaysAgo,
          endTime: now,
          types: types,
        );
        _sleepData = _generateChartData(healthData, HealthDataType.SLEEP_IN_BED);
        _stepsData = _generateChartData(healthData, HealthDataType.STEPS);
      } catch (e, s) {
        developer.log('Error fetching weekly health data.',
            name: 'HealthState', error: e, stackTrace: s);
      }
    }
  }

  List<BarChartGroupData> _generateChartData(
    List<HealthDataPoint> healthData,
    HealthDataType dataType,
  ) {
    List<double> weeklyData = List.filled(7, 0.0);
    for (var data in healthData) {
      if (data.type == dataType) {
        final dayIndex = data.dateFrom.weekday - 1;
        weeklyData[dayIndex] +=
            (data.value as NumericHealthValue).numericValue.toDouble();
      }
    }

    if (dataType == HealthDataType.SLEEP_IN_BED) {
      for (int i = 0; i < weeklyData.length; i++) {
        weeklyData[i] /= 60; // Convert minutes to hours
      }
    }

    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: weeklyData[index],
            color: dataType == HealthDataType.SLEEP_IN_BED
                ? Colors.lightBlue
                : Colors.orange,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    super.dispose();
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthState = Provider.of<HealthState>(context);
    final today = DateFormat('yyyy/M/d E', 'ja_JP').format(DateTime.now());
    final eventText = healthState.todaysEvents.isNotEmpty
        ? healthState.todaysEvents.first.title ?? '今日の予定はありません'
        : '今日の予定はありません';
    final progress = healthState.stepGoal > 0
        ? (healthState.steps / healthState.stepGoal).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ヘルスケア'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/goal_setting'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'メニュー',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('今日のデータ'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('週間レポート'),
              onTap: () => context.push('/weekly_report'),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              today,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (kIsWeb)
              const Text(
                "ヘルスケア機能はWeb版では利用できません。",
                style: TextStyle(color: Colors.red),
              )
            else ...[
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 40),
                  const SizedBox(width: 10),
                  Text(
                    '${healthState.steps}歩',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '目標: ${healthState.stepGoal}歩',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.bedtime, size: 40),
                  const SizedBox(width: 10),
                  Text(
                    '${healthState.sleepHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Text(
                '睡眠時間',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 80),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network('https://i.imgur.com/8x81gdH.png', height: 200),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(204),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        eventText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
