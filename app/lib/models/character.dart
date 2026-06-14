class Character {
  final int id;
  final String name;
  final String jobClass;
  final int level;
  final int totalExp;
  final int hp;
  final int maxHp;
  final int mp;
  final int speed;
  final int luck;
  final int streakDays;

  Character({
    required this.id,
    required this.name,
    required this.jobClass,
    required this.level,
    required this.totalExp,
    required this.hp,
    required this.maxHp,
    required this.mp,
    required this.speed,
    required this.luck,
    required this.streakDays,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      jobClass: json['job_class'],
      level: json['level'],
      totalExp: json['total_exp'],
      hp: json['hp'],
      maxHp: json['max_hp'],
      mp: json['mp'],
      speed: json['speed'],
      luck: json['luck'],
      streakDays: json['streak_days'],
    );
  }

  double get hpPercent => hp / maxHp;
  int get expToNext => _expForLevel(level + 1) - totalExp;

  int _expForLevel(int targetLevel) {
    int total = 0;
    int needed = 100;
    for (int i = 1; i < targetLevel; i++) {
      total += needed;
      needed = (needed * 1.15).toInt();
    }
    return total;
  }
}
