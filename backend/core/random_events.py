"""출퇴근 중 랜덤 이벤트 시스템"""

import random

RANDOM_EVENTS = [
    # === 긍정 이벤트 ===
    {
        "code": "empty_train",
        "name": "텅 빈 지하철",
        "description": "기적적으로 객차가 비어있다! 앉아서 출근!",
        "icon": "🎉",
        "type": "positive",
        "probability": 0.05,
        "effect": {"hp_recovery": 20, "exp_bonus": 100},
    },
    {
        "code": "found_money",
        "name": "바닥에 천원",
        "description": "출근길에 천원을 주웠다. 오늘 운수 좋은 날!",
        "icon": "💰",
        "type": "positive",
        "probability": 0.03,
        "effect": {"luck_boost": 10, "exp_bonus": 50},
    },
    {
        "code": "perfect_transfer",
        "name": "환승 퍼펙트",
        "description": "내리자마자 바로 환승 열차 도착. 시간 절약!",
        "icon": "⚡",
        "type": "positive",
        "probability": 0.08,
        "effect": {"speed_boost": 20, "exp_bonus": 80},
    },
    {
        "code": "nice_weather",
        "name": "완벽한 날씨",
        "description": "선선한 바람, 맑은 하늘. 출근이 즐겁다.",
        "icon": "🌤️",
        "type": "positive",
        "probability": 0.10,
        "effect": {"mp_recovery": 15, "exp_bonus": 30},
    },
    {
        "code": "celebrity_spot",
        "name": "연예인 발견",
        "description": "지하철에서 연예인을 봤다! 럭 대폭 상승.",
        "icon": "⭐",
        "type": "positive",
        "probability": 0.02,
        "effect": {"luck_boost": 30, "exp_bonus": 200},
    },
    # === 부정 이벤트 ===
    {
        "code": "train_delay",
        "name": "열차 지연",
        "description": "승객 안전 확인으로 5분 지연... 인내력 소모.",
        "icon": "⏰",
        "type": "negative",
        "probability": 0.12,
        "effect": {"mp_damage": 10, "exp_bonus": 20},
    },
    {
        "code": "crowded_hell",
        "name": "지옥의 혼잡",
        "description": "사람에 끼여서 숨쉬기도 힘들다.",
        "icon": "😵",
        "type": "negative",
        "probability": 0.15,
        "effect": {"hp_damage": 10, "exp_bonus": 50},
    },
    {
        "code": "rain_no_umbrella",
        "name": "우산 깜빡",
        "description": "비 오는데 우산이 없다. HP 감소.",
        "icon": "🌧️",
        "type": "negative",
        "probability": 0.08,
        "effect": {"hp_damage": 15, "exp_bonus": 40},
    },
    {
        "code": "missed_bus",
        "name": "버스 놓침",
        "description": "눈앞에서 버스가 출발했다... 다음 버스 10분 후.",
        "icon": "🚌",
        "type": "negative",
        "probability": 0.10,
        "effect": {"speed_damage": 5, "exp_bonus": 30},
    },
    {
        "code": "phone_dead",
        "name": "폰 배터리 방전",
        "description": "출근길에 폰이 꺼졌다. MP 대폭 감소.",
        "icon": "📱",
        "type": "negative",
        "probability": 0.05,
        "effect": {"mp_damage": 25, "exp_bonus": 60},
    },
    # === 특수 이벤트 ===
    {
        "code": "mystery_passenger",
        "name": "수상한 승객",
        "description": "옆자리 승객이 말을 건다. '출퇴근이 힘드시죠?'... 경험치 2배!",
        "icon": "🎭",
        "type": "special",
        "probability": 0.01,
        "effect": {"exp_multiplier": 2.0},
    },
    {
        "code": "time_slip",
        "name": "타임슬립",
        "description": "잠깐 졸았는데 벌써 도착역이다. 시간이 순간이동!",
        "icon": "🕐",
        "type": "special",
        "probability": 0.03,
        "effect": {"exp_bonus": 150, "hp_recovery": 10},
    },
]


def roll_random_event(luck: int = 5) -> dict | None:
    """럭 스탯 기반 랜덤 이벤트 발생"""
    luck_modifier = 1.0 + (luck * 0.02)  # 럭 50이면 확률 2배

    for event in RANDOM_EVENTS:
        adjusted_prob = event["probability"]
        if event["type"] == "positive" or event["type"] == "special":
            adjusted_prob *= luck_modifier
        elif event["type"] == "negative":
            adjusted_prob /= luck_modifier

        if random.random() < adjusted_prob:
            return event

    return None
