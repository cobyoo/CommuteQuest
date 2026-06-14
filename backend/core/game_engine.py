"""게임 핵심 로직 엔진"""

from enum import Enum

from core.config import settings


class DungeonGrade(str, Enum):
    HELL = "hell"       # 2호선
    HARD = "hard"       # 9호선 급행
    NORMAL = "normal"   # 신분당선
    FIELD = "field"     # 버스
    BONUS = "bonus"     # 도보/자전거


class JobClass(str, Enum):
    INTERN = "intern"
    STAFF = "staff"
    SENIOR = "senior"
    MANAGER = "manager"
    DIRECTOR = "director"
    EXECUTIVE = "executive"
    LEGEND = "legend"


# 던전 등급별 경험치 배율
DUNGEON_MULTIPLIER = {
    DungeonGrade.HELL: 2.0,
    DungeonGrade.HARD: 1.8,
    DungeonGrade.NORMAL: 1.2,
    DungeonGrade.FIELD: 1.0,
    DungeonGrade.BONUS: 1.5,
}

# 직업별 필요 레벨
JOB_LEVEL_REQUIREMENTS = {
    JobClass.INTERN: 1,
    JobClass.STAFF: 10,
    JobClass.SENIOR: 25,
    JobClass.MANAGER: 45,
    JobClass.DIRECTOR: 70,
    JobClass.EXECUTIVE: 100,
    JobClass.LEGEND: 150,
}


def calculate_exp(commute_minutes: int, dungeon_grade: DungeonGrade) -> int:
    """출퇴근 시간 기반 경험치 계산"""
    base_exp = commute_minutes * settings.BASE_EXP_PER_MINUTE
    multiplier = DUNGEON_MULTIPLIER[dungeon_grade]
    return int(base_exp * multiplier)


def calculate_level(total_exp: int) -> int:
    """총 경험치로 레벨 계산 (레벨당 필요 경험치 점진 증가)"""
    level = 1
    exp_needed = 100
    remaining = total_exp

    while remaining >= exp_needed:
        remaining -= exp_needed
        level += 1
        exp_needed = int(exp_needed * 1.15)

    return level


def get_job_class(level: int) -> JobClass:
    """레벨에 따른 직업 반환"""
    current_job = JobClass.INTERN
    for job, required_level in JOB_LEVEL_REQUIREMENTS.items():
        if level >= required_level:
            current_job = job
    return current_job


def check_boss_clear(target_arrival: str, actual_arrival: str) -> bool:
    """정시 도착 여부 (보스 클리어 판정)"""
    return actual_arrival <= target_arrival


def calculate_late_penalty(late_minutes: int) -> int:
    """지각 시 HP 페널티"""
    return min(late_minutes * settings.LATE_HP_PENALTY, 100)
