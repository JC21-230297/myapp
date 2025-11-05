
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  GoalSettingScreenState createState() => GoalSettingScreenState();
}

class GoalSettingScreenState extends State<GoalSettingScreen> {
  late SharedPreferences _prefs;
  final _stepsController = TextEditingController();
  final _sleepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _stepsController.text = (_prefs.getInt('stepGoal') ?? 10000).toString();
      _sleepController.text = (_prefs.getInt('sleepGoal') ?? 8).toString();
    });
  }

  Future<void> _saveGoals() async {
    final stepGoal = int.tryParse(_stepsController.text) ?? 10000;
    final sleepGoal = int.tryParse(_sleepController.text) ?? 8;
    await _prefs.setInt('stepGoal', stepGoal);
    await _prefs.setInt('sleepGoal', sleepGoal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目標設定')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _stepsController,
                decoration: const InputDecoration(
                  labelText: '毎日の目標歩数',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _sleepController,
                decoration: const InputDecoration(
                  labelText: '毎日の目標睡眠時間（時間）',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveGoals();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('目標を保存しました')));
                  FocusScope.of(context).unfocus();
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
