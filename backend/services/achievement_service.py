"""업적 달성 체크 및 보상 지급 서비스"""

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from models.achievement import Achievement, CharacterAchievement
from models.character import Character, CommuteLog


async def check_achievements(
    db: AsyncSession, character: Character
) -> list[dict]:
    """출퇴근 완료 후 새로 달성한 업적 체크"""
    # 이미 달성한 업적 ID 조회
    result = await db.execute(
        select(CharacterAchievement.achievement_id).where(
            CharacterAchievement.character_id == character.id
        )
    )
    unlocked_ids = set(result.scalars().all())

    # 전체 업적 조회
    result = await db.execute(select(Achievement))
    all_achievements = result.scalars().all()

    # 캐릭터 통계 조회
    stats = await _get_character_stats(db, character)

    # 달성 체크
    newly_unlocked = []
    for achievement in all_achievements:
        if achievement.id in unlocked_ids:
            continue

        if _check_condition(achievement, character, stats):
            # 업적 달성!
            char_achievement = CharacterAchievement(
                character_id=character.id,
                achievement_id=achievement.id,
            )
            db.add(char_achievement)

            # 보상 경험치 지급
            if achievement.reward_exp > 0:
                character.total_exp += achievement.reward_exp

            newly_unlocked.append({
                "code": achievement.code,
                "name": achievement.name,
                "description": achievement.description,
                "icon": achievement.icon,
                "reward_exp": achievement.reward_exp,
                "reward_title": achievement.reward_title,
            })

    if newly_unlocked:
        await db.commit()

    return newly_unlocked


async def _get_character_stats(db: AsyncSession, character: Character) -> dict:
    """캐릭터의 누적 통계"""
    # 총 출퇴근 횟수
    result = await db.execute(
        select(func.count()).where(CommuteLog.character_id == character.id)
    )
    total_commutes = result.scalar() or 0

    # 보스 클리어 횟수
    result = await db.execute(
        select(func.count()).where(
            CommuteLog.character_id == character.id,
            CommuteLog.boss_cleared == True,
        )
    )
    boss_clears = result.scalar() or 0

    # 지옥 던전 클리어 횟수
    result = await db.execute(
        select(func.count()).where(
            CommuteLog.character_id == character.id,
            CommuteLog.dungeon_grade == "hell",
            CommuteLog.boss_cleared == True,
        )
    )
    hell_clears = result.scalar() or 0

    return {
        "total_commutes": total_commutes,
        "boss_clears": boss_clears,
        "hell_clears": hell_clears,
        # 아래는 MVP에서 간단히 0 처리, 이후 확장
        "monday_boss_clears": 0,
        "early_arrivals": 0,
        "weekend_commutes": 0,
    }


def _check_condition(achievement: Achievement, character: Character, stats: dict) -> bool:
    """업적 조건 달성 여부 체크"""
    condition_type = achievement.condition_type
    required = achievement.condition_value

    if condition_type == "streak_days":
        return character.streak_days >= required
    elif condition_type == "boss_clears":
        return stats["boss_clears"] >= required
    elif condition_type == "total_commutes":
        return stats["total_commutes"] >= required
    elif condition_type == "level":
        return character.level >= required
    elif condition_type == "hell_clears":
        return stats["hell_clears"] >= required
    elif condition_type == "monday_boss_clears":
        return stats["monday_boss_clears"] >= required
    elif condition_type == "early_arrivals":
        return stats["early_arrivals"] >= required
    elif condition_type == "weekend_commutes":
        return stats["weekend_commutes"] >= required

    return False
