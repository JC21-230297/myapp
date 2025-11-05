
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data class for a Mameshiba Character
class GachaCharacter {
  final String name;
  final String imageUrl;

  GachaCharacter({required this.name, required this.imageUrl});

  // For JSON serialization
  factory GachaCharacter.fromJson(Map<String, dynamic> json) {
    return GachaCharacter(
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}

class GachaState with ChangeNotifier {
  GachaCharacter? _lastReward;
  GachaCharacter? get lastReward => _lastReward;

  final List<GachaCharacter> _gachaHistory = [];
  List<GachaCharacter> get gachaHistory => _gachaHistory;

  // Mameshiba character rewards list from the official website
  static final List<GachaCharacter> _rewards = [
    GachaCharacter(name: '枝豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-edamame.png'),
    GachaCharacter(name: '黒豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-kuromame.png'),
    GachaCharacter(name: 'ピーナッしば', imageUrl: 'https://mame-shiba.com/img/character/std-peanut.png'),
    GachaCharacter(name: '納豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-natto.png'),
    GachaCharacter(name: 'そら豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-sora.png'),
    GachaCharacter(name: 'コーヒー豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-coffee.png'),
    GachaCharacter(name: 'カカオしば', imageUrl: 'https://mame-shiba.com/img/character/std-cacao.png'),
    GachaCharacter(name: 'チリビーンしば', imageUrl: 'https://mame-shiba.com/img/character/std-chili.png'),
    GachaCharacter(name: 'ひよこ豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-chickpea.png'),
    GachaCharacter(name: '刀豆しば', imageUrl: 'https://mame-shiba.com/img/character/std-sword.png'),
  ];

  GachaState() {
    loadGachaData();
  }

  Future<void> loadGachaData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('gachaHistory') ?? [];
    _gachaHistory.clear();
    _gachaHistory.addAll(historyJson.map((j) => GachaCharacter.fromJson(jsonDecode(j))));
    
    final lastRewardJson = prefs.getString('lastReward');
    if (lastRewardJson != null) {
      _lastReward = GachaCharacter.fromJson(jsonDecode(lastRewardJson));
    }
    
    notifyListeners();
  }

  GachaCharacter drawGacha() {
    final random = Random();
    final reward = _rewards[random.nextInt(_rewards.length)];
    _lastReward = reward;
    _gachaHistory.insert(0, reward);

    _saveGachaData();
    notifyListeners();
    return reward; // Return the new character
  }

  Future<void> _saveGachaData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _gachaHistory.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('gachaHistory', historyJson);
    
    if (_lastReward != null) {
      await prefs.setString('lastReward', jsonEncode(_lastReward!.toJson()));
    }
  }
}

class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gachaState = Provider.of<GachaState>(context);
    
    final imageUrl = gachaState.lastReward?.imageUrl ?? 'https://mame-shiba.com/img/character/std-edamame.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('まめしばガチャ'),
      ),
      body: Row(
        children: [
          // Left Side: Gacha Controls and History
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 20),
                      backgroundColor: Colors.lightGreen, // Mameshiba green
                    ),
                    onPressed: () {
                      final newCharacter = gachaState.drawGacha();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(newCharacter.imageUrl),
                              ),
                              const SizedBox(width: 16),
                              Flexible(
                                child: Text('ねぇ知ってる？「${newCharacter.name}」だよ。'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.amberAccent, // Mameshiba-style yellow
                        ),
                      );
                    },
                    child: const Text('ガチャを引く'),
                  ),
                  const SizedBox(height: 24),
                   Text(
                      '前回見つけたまめしば: ${gachaState.lastReward?.name ?? "まだいないよ"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    '発見履歴',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: gachaState.gachaHistory.isEmpty
                        ? const Center(child: Text('まだ何も見つけていないよ'))
                        : ListView.builder(
                            itemCount: gachaState.gachaHistory.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const Icon(Icons.pets), // Paw icon
                                title: Text(gachaState.gachaHistory[index].name),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Right Side: Character Image
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gachaState.lastReward?.name ?? '???',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          height: 250,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 100,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
