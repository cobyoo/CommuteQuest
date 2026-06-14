import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/character_provider.dart';
import '../../widgets/stat_bar.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  void initState() {
    super.initState();
    _loadCharacter();
  }

  Future<void> _loadCharacter() async {
    final api = context.read<AuthProvider>().api;
    await context.read<CharacterProvider>().loadCharacter(api);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 캐릭터')),
      body: Consumer<CharacterProvider>(
        builder: (_, cp, __) {
          if (cp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!cp.hasCharacter) {
            return _buildCreateCharacter(context);
          }
          return _buildCharacterView(cp);
        },
      ),
    );
  }

  Widget _buildCreateCharacter(BuildContext context) {
    final controller = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 64),
            const SizedBox(height: 16),
            const Text('캐릭터를 생성하세요', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '캐릭터 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final api = context.read<AuthProvider>().api;
                await context.read<CharacterProvider>().createCharacter(api, controller.text);
              },
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterView(CharacterProvider cp) {
    final char = cp.character!;
    final jobName = GameConstants.jobClassNames[char.jobClass] ?? char.jobClass;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 프로필 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      char.name[0],
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(char.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$jobName · Lv.${char.level}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('연속 출근 ${char.streakDays}일', style: TextStyle(color: Colors.amber[300])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 스탯
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('스탯', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  StatBar(label: 'HP', value: char.hp, max: char.maxHp, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  StatBar(label: 'MP (인내력)', value: char.mp, max: 100, color: Colors.blueAccent),
                  const SizedBox(height: 12),
                  StatBar(label: 'SPD', value: char.speed, max: 100, color: Colors.greenAccent),
                  const SizedBox(height: 12),
                  StatBar(label: 'LUCK', value: char.luck, max: 100, color: Colors.amberAccent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 경험치
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('경험치', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.6, // placeholder
                    backgroundColor: Colors.grey[800],
                    color: Theme.of(context).primaryColor,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 8),
                  Text('총 ${char.totalExp} EXP · 다음 레벨까지 ${char.expToNext} EXP'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
