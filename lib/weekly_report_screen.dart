
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'health_service.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final healthState = Provider.of<HealthState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('週間レポート')),
      body: kIsWeb
          ? const Center(child: Text("週間レポート機能はWeb版では利用できません。"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildChart('睡眠 (時間)', healthState.sleepData),
                  const SizedBox(height: 40),
                  _buildChart('歩数', healthState.stepsData),
                ],
              ),
            ),
    );
  }

  Widget _buildChart(String title, List<BarChartGroupData> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              barGroups: data,
              alignment: BarChartAlignment.spaceAround,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      );
                      final week = ['月', '火', '水', '木', '金', '土', '日'];
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(week[value.toInt()], style: style),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ],
    );
  }
}
