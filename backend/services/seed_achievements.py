"""업적 데이터 시드 스크립트"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.achievements import ACHIEVEMENT_DEFINITIONS
from models.achievement import Achievement


async def seed_achievements(db: AsyncSession) -> int:
    """업적 정의를 DB에 삽입 (이미 존재하면 스킵)"""
    inserted = 0
    for defn in ACHIEVEMENT_DEFINITIONS:
        result = await db.execute(
            select(Achievement).where(Achievement.code == defn["code"])
        )
        if result.scalar_one_or_none():
            continue

        achievement = Achievement(
            code=defn["code"],
            name=defn["name"],
            description=defn["description"],
            icon=defn["icon"],
            category=defn["category"],
            condition_type=defn["condition_type"],
            condition_value=defn["condition_value"],
            reward_exp=defn["reward_exp"],
            reward_title=defn.get("reward_title"),
            is_hidden=defn.get("is_hidden", False),
        )
        db.add(achievement)
        inserted += 1

    await db.commit()
    return inserted
