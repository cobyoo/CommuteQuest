import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/character_provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _selectedSlot = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().api;
    try {
      _items = await api.getShop();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _buy(String code, String name) async {
    final api = context.read<AuthProvider>().api;
    try {
      final result = await api.buyEquipment(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$name 구매 완료! (남은 EXP: ${result['remaining_exp']})"),
            backgroundColor: Colors.green,
          ),
        );
        // 캐릭터 정보 갱신
        context.read<CharacterProvider>().loadCharacter(api);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSlotFilter(),
              Expanded(child: _buildItemGrid()),
            ],
          );
  }

  Widget _buildSlotFilter() {
    const slots = {
      'all': '전체',
      'head': '머리',
      'body': '몸통',
      'accessory': '액세서리',
      'consumable': '소모품',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: slots.entries.map((e) {
          final selected = _selectedSlot == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) => setState(() => _selectedSlot = e.key),
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemGrid() {
    final filtered = _selectedSlot == 'all'
        ? _items
        : _items.where((i) => i['slot'] == _selectedSlot).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildShopCard(filtered[i]),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> item) {
    final stats = Map<String, String>.from(item['stats'] ?? {});
    final rarity = item['rarity'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _rarityColor(rarity).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _rarityColor(rarity).withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(item['icon'], style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _rarityColor(rarity),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildRarityBadge(rarity),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: stats.entries.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${s.key} ${s.value}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // 구매 버튼
            Column(
              children: [
                Text(
                  '${item['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                    fontSize: 16,
                  ),
                ),
                const Text('EXP', style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _buy(item['code'], item['name']),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('구매'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge(String rarity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _rarityColor(rarity).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _rarityLabel(rarity),
        style: TextStyle(fontSize: 10, color: _rarityColor(rarity)),
      ),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _rarityLabel(String rarity) {
    switch (rarity) {
      case 'common':
        return '일반';
      case 'uncommon':
        return '고급';
      case 'rare':
        return '희귀';
      case 'epic':
        return '에픽';
      case 'legendary':
        return '전설';
      default:
        return rarity;
    }
  }
}
