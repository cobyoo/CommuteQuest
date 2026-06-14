"""칭호 시스템 — 캐릭터 이름 위에 표시되는 타이틀"""

TITLE_DEFINITIONS = [
    # 기본 칭호
    {"code": "newbie", "name": "신입 모험가", "condition": "가입 즉시", "color": "#AAAAAA"},
    {"code": "commuter", "name": "출근러", "condition": "첫 출퇴근 완료", "color": "#FFFFFF"},

    # 연속출근 칭호
    {"code": "fire_commuter", "name": "불꽃 출근러", "condition": "7일 연속", "color": "#FF6B35"},
    {"code": "iron_will", "name": "철의 의지", "condition": "30일 연속", "color": "#4ECDC4"},
    {"code": "time_lord", "name": "시간의 지배자", "condition": "100일 연속", "color": "#FFD700"},
    {"code": "legend_worker", "name": "전설의 직장인", "condition": "365일 연속", "color": "#FF1493"},

    # 특수 칭호
    {"code": "boss_hunter", "name": "보스 헌터", "condition": "보스 10회", "color": "#E74C3C"},
    {"code": "on_time_master", "name": "정시의 달인", "condition": "보스 50회", "color": "#9B59B6"},
    {"code": "hell_survivor", "name": "지옥철 서바이버", "condition": "2호선 10회", "color": "#C0392B"},
    {"code": "early_bird", "name": "얼리버드", "condition": "10분 일찍 5회", "color": "#F39C12"},
    {"code": "monday_immune", "name": "월요병 면역", "condition": "월요일 5회 정시", "color": "#2ECC71"},
    {"code": "weekend_warrior", "name": "주말 전사", "condition": "주말 출근 5회", "color": "#8E44AD"},
    {"code": "rich_commuter", "name": "부자 통근러", "condition": "EXP 10만 이상 보유", "color": "#F1C40F"},
    {"code": "collector", "name": "수집왕", "condition": "장비 10개 보유", "color": "#1ABC9C"},
    {"code": "full_equipped", "name": "풀장비", "condition": "3슬롯 모두 장착", "color": "#3498DB"},
]
