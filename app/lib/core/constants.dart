class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String health = 'http://localhost:8000/health';
}

class GameConstants {
  static const Map<String, String> jobClassNames = {
    'intern': '인턴',
    'staff': '사원',
    'senior': '대리',
    'manager': '과장',
    'director': '임원',
    'executive': '회장',
    'legend': '은퇴 전설',
  };

  static const Map<String, String> dungeonNames = {
    'hell': '2호선 🔴',
    'hard': '9호선 급행 🟠',
    'normal': '신분당선 🟡',
    'field': '버스 🟢',
    'bonus': '도보/자전거 🔵',
  };
}
