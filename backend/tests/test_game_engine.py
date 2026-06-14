"""게임 엔진 유닛 테스트"""

from core.game_engine import (
    calculate_exp,
    calculate_level,
    get_job_class,
    calculate_late_penalty,
    DungeonGrade,
    JobClass,
)


def test_calculate_exp_hell_dungeon():
    # 45분 * 10 exp/min * 2.0 배율 = 900
    exp = calculate_exp(45, DungeonGrade.HELL)
    assert exp == 900


def test_calculate_exp_field():
    # 30분 * 10 * 1.0 = 300
    exp = calculate_exp(30, DungeonGrade.FIELD)
    assert exp == 300


def test_calculate_level_starts_at_1():
    assert calculate_level(0) == 1


def test_calculate_level_after_100_exp():
    assert calculate_level(100) == 2


def test_get_job_class_intern():
    assert get_job_class(1) == JobClass.INTERN


def test_get_job_class_staff():
    assert get_job_class(10) == JobClass.STAFF


def test_get_job_class_legend():
    assert get_job_class(150) == JobClass.LEGEND


def test_late_penalty_capped_at_100():
    penalty = calculate_late_penalty(999)
    assert penalty == 100
