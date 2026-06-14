from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import get_db
from models.character import Character

router = APIRouter()


@router.get("/level")
async def ranking_by_level(db: AsyncSession = Depends(get_db)):
    """레벨 랭킹 TOP 50"""
    result = await db.execute(
        select(Character).order_by(Character.level.desc(), Character.total_exp.desc()).limit(50)
    )
    characters = result.scalars().all()
    return {
        "rankings": [
            {"rank": i + 1, "name": c.name, "level": c.level, "job_class": c.job_class}
            for i, c in enumerate(characters)
        ]
    }


@router.get("/streak")
async def ranking_by_streak(db: AsyncSession = Depends(get_db)):
    """연속 출근 랭킹 TOP 50"""
    result = await db.execute(
        select(Character).order_by(Character.streak_days.desc()).limit(50)
    )
    characters = result.scalars().all()
    return {
        "rankings": [
            {"rank": i + 1, "name": c.name, "streak_days": c.streak_days, "level": c.level}
            for i, c in enumerate(characters)
        ]
    }
