import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().api;
    try {
      _data = await api.getAchievements();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('업적')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_data == null) return const Center(child: Text('업적을 불러올 수 없습니다'));

    final achievements = List<Map<String, dynamic>>.from(_data!['achievements']);
    final filtered = _selectedCategory == 'all'
        ? achievements
        : achievements.where((a) => a['category'] == _selectedCategory).toList();

    return Column(
      children: [
        // 진행률 헤더
        _buildProgressHeader(),
        // 카테고리 필터
        _buildCategoryFilter(),
        // 업적 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildAchievementCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final unlocked = _data!['unlocked'] as int;
    final total = _data!['total'] as int;
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$unlocked / $total',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.amberAccent,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          const Text('업적 달성률'),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    const categories = {
      'all': '전체',
      'streak': '연속출근',
      'boss': '보스',
      'commute': '출퇴근',
      'level': '레벨',
      'special': '특수',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.entries.map((e) {
          final selected = _selectedCategory == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) => setState(() => _selectedCategory = e.key),
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final unlocked = achievement['unlocked'] as bool;
    final isHidden = achievement['is_hidden'] as bool;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: unlocked ? null : Colors.grey[900],
      child: ListTile(
        leading: Text(
          unlocked ? achievement['icon'] : (isHidden ? '❓' : achievement['icon']),
          style: TextStyle(
            fontSize: 32,
            color: unlocked ? null : Colors.grey,
          ),
        ),
        title: Text(
          achievement['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? Colors.white : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement['description'],
              style: TextStyle(color: unlocked ? Colors.white70 : Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (achievement['reward_exp'] > 0)
                  _buildRewardChip('+${achievement['reward_exp']} EXP', Colors.blue),
                if (achievement['reward_title'] != null) ...[
                  const SizedBox(width: 6),
                  _buildRewardChip(achievement['reward_title'], Colors.amber),
                ],
              ],
            ),
          ],
        ),
        trailing: unlocked
            ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28)
            : Icon(Icons.lock_outline, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildRewardChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
