import 'package:flutter/material.dart';

class DungeonCard extends StatelessWidget {
  final String grade;
  final String name;
  final VoidCallback onTap;

  const DungeonCard({
    super.key,
    required this.grade,
    required this.name,
    required this.onTap,
  });

  Color get _gradeColor {
    switch (grade) {
      case 'hell':
        return Colors.red;
      case 'hard':
        return Colors.orange;
      case 'normal':
        return Colors.yellow;
      case 'field':
        return Colors.green;
      case 'bonus':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get _expInfo {
    switch (grade) {
      case 'hell':
        return 'EXP x2.0';
      case 'hard':
        return 'EXP x1.8';
      case 'normal':
        return 'EXP x1.2';
      case 'field':
        return 'EXP x1.0';
      case 'bonus':
        return 'EXP x1.5 + 체력 보너스';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _gradeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_subway, color: _gradeColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _expInfo,
                      style: TextStyle(color: _gradeColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
