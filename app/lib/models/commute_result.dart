class CommuteResult {
  final int commuteMinutes;
  final String dungeonGrade;
  final int expEarned;
  final bool bossCleared;
  final int hpPenalty;
  final bool levelUp;
  final int newLevel;
  final bool jobPromoted;
  final String? newJob;

  CommuteResult({
    required this.commuteMinutes,
    required this.dungeonGrade,
    required this.expEarned,
    required this.bossCleared,
    required this.hpPenalty,
    required this.levelUp,
    required this.newLevel,
    required this.jobPromoted,
    this.newJob,
  });

  factory CommuteResult.fromJson(Map<String, dynamic> json) {
    return CommuteResult(
      commuteMinutes: json['commute_minutes'],
      dungeonGrade: json['dungeon_grade'],
      expEarned: json['exp_earned'],
      bossCleared: json['boss_cleared'],
      hpPenalty: json['hp_penalty'],
      levelUp: json['level_up'],
      newLevel: json['new_level'],
      jobPromoted: json['job_promoted'],
      newJob: json['new_job'],
    );
  }
}
