import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _levelRankings = [];
  List<Map<String, dynamic>> _streakRankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    final api = context.read<AuthProvider>().api;
    try {
      _levelRankings = await api.getRankings('level');
      _streakRankings = await api.getRankings('streak');
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('랭킹'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '레벨 랭킹'),
            Tab(text: '연속 출근'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRankingList(_levelRankings, isLevel: true),
                _buildRankingList(_streakRankings, isLevel: false),
              ],
            ),
    );
  }

  Widget _buildRankingList(List<Map<String, dynamic>> rankings, {required bool isLevel}) {
    if (rankings.isEmpty) {
      return const Center(child: Text('아직 랭킹 데이터가 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rankings.length,
      itemBuilder: (_, i) {
        final r = rankings[i];
        final rank = r['rank'];
        final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank';

        return Card(
          child: ListTile(
            leading: Text(medal, style: const TextStyle(fontSize: 24)),
            title: Text(r['name'] ?? ''),
            subtitle: isLevel
                ? Text('Lv.${r['level']} · ${r['job_class']}')
                : Text('${r['streak_days']}일 연속 · Lv.${r['level']}'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
