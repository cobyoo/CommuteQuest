import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/commute_provider.dart';
import '../../widgets/dungeon_card.dart';

class CommuteScreen extends StatelessWidget {
  const CommuteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('던전 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Consumer<CommuteProvider>(
        builder: (_, commute, __) {
          if (commute.state == CommuteState.commuting) {
            return _buildCommutingView(context, commute);
          }
          return _buildDungeonSelection(context);
        },
      ),
    );
  }

  Widget _buildDungeonSelection(BuildContext context) {
    final dungeons = GameConstants.dungeonNames.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 던전을 선택하세요',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('어떤 교통수단으로 출근하시나요?'),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: dungeons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final entry = dungeons[i];
                return DungeonCard(
                  grade: entry.key,
                  name: entry.value,
                  onTap: () => _startCommute(context, entry.key),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommutingView(BuildContext context, CommuteProvider commute) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, size: 80, color: Colors.amber),
          const SizedBox(height: 24),
          Text(
            '던전 공략 중...',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            GameConstants.dungeonNames[commute.currentDungeon] ?? '',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: () => _endCommute(context),
            icon: const Icon(Icons.flag),
            label: const Text('도착! (던전 클리어)', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _startCommute(BuildContext context, String grade) {
    final commute = context.read<CommuteProvider>();
    final api = context.read<AuthProvider>().api;
    final targetArrival = DateTime.now().add(const Duration(hours: 1));
    commute.startCommute(api, grade, targetArrival);
  }

  void _endCommute(BuildContext context) async {
    final commute = context.read<CommuteProvider>();
    final api = context.read<AuthProvider>().api;
    final result = await commute.endCommute(api);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(result.bossCleared ? '보스 클리어!' : '던전 실패...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('획득 경험치: +${result.expEarned} EXP'),
              Text('소요 시간: ${result.commuteMinutes}분'),
              if (result.levelUp) Text('레벨 업! Lv.${result.newLevel}'),
              if (result.jobPromoted) Text('전직! → ${result.newJob}'),
              if (result.hpPenalty > 0) Text('HP 페널티: -${result.hpPenalty}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                commute.reset();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
