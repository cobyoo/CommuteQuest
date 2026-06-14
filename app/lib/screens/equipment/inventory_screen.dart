import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/character_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final api = context.read<AuthProvider>().api;
    try {
      _items = await api.getInventory();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _toggleEquip(String code, bool isEquipped, String slot) async {
    if (slot == 'consumable') return;

    final api = context.read<AuthProvider>().api;
    try {
      if (isEquipped) {
        await api.unequipItem(code);
      } else {
        await api.equipItem(code);
      }
      await _load();
      if (mounted) {
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text('인벤토리가 비어있습니다', style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text('상점에서 장비를 구매해보세요!', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      );
    }

    // 슬롯별 그룹핑
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in _items) {
      final slot = item['slot'] as String;
      grouped.putIfAbsent(slot, () => []);
      grouped[slot]!.add(item);
    }

    const slotNames = {
      'head': '머리',
      'body': '몸통',
      'accessory': '액세서리',
      'consumable': '소모품',
    };

    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                slotNames[entry.key] ?? entry.key,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((item) => _buildInventoryCard(item)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final isEquipped = item['is_equipped'] as bool;
    final stats = Map<String, String>.from(item['stats'] ?? {});
    final rarity = item['rarity'] as String;
    final slot = item['slot'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEquipped
            ? BorderSide(color: _rarityColor(rarity), width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _rarityColor(rarity).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item['icon'], style: const TextStyle(fontSize: 24)),
              ),
            ),
            if (isEquipped)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              item['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _rarityColor(rarity),
              ),
            ),
            if (isEquipped) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('장착중', style: TextStyle(fontSize: 10, color: Colors.green)),
              ),
            ],
          ],
        ),
        subtitle: Wrap(
          spacing: 6,
          children: stats.entries.map((s) {
            return Text(
              '${s.key} ${s.value}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            );
          }).toList(),
        ),
        trailing: slot == 'consumable'
            ? null
            : IconButton(
                icon: Icon(
                  isEquipped ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: isEquipped ? Colors.redAccent : Colors.greenAccent,
                ),
                onPressed: () => _toggleEquip(item['code'], isEquipped, slot),
              ),
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
}
