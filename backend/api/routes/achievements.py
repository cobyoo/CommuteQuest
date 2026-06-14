from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.deps import get_current_user
from models.database import get_db
from models.achievement import Achievement, CharacterAchievement
from models.character import Character
from models.user import User

router = APIRouter()


@router.get("/")
async def list_achievements(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """전체 업적 목록 (히든 제외) + 달성 여부"""
    # 캐릭터 조회
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()

    # 달성한 업적 ID
    unlocked_ids = set()
    if character:
        result = await db.execute(
            select(CharacterAchievement.achievement_id).where(
                CharacterAchievement.character_id == character.id
            )
        )
        unlocked_ids = set(result.scalars().all())

    # 전체 업적 (히든은 달성한 것만 표시)
    result = await db.execute(select(Achievement).order_by(Achievement.category, Achievement.condition_value))
    achievements = result.scalars().all()

    items = []
    for a in achievements:
        unlocked = a.id in unlocked_ids
        if a.is_hidden and not unlocked:
            continue
        items.append({
            "code": a.code,
            "name": a.name,
            "description": a.description,
            "icon": a.icon,
            "category": a.category,
            "condition_value": a.condition_value,
            "reward_exp": a.reward_exp,
            "reward_title": a.reward_title,
            "unlocked": unlocked,
            "is_hidden": a.is_hidden,
        })

    total = len([a for a in achievements if not a.is_hidden])
    unlocked_count = len(unlocked_ids)

    return {
        "total": total,
        "unlocked": unlocked_count,
        "progress": f"{unlocked_count}/{total}",
        "achievements": items,
    }


@router.get("/recent")
async def recent_achievements(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """최근 달성한 업적 5개"""
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        return {"achievements": []}

    result = await db.execute(
        select(CharacterAchievement, Achievement)
        .join(Achievement, CharacterAchievement.achievement_id == Achievement.id)
        .where(CharacterAchievement.character_id == character.id)
        .order_by(CharacterAchievement.unlocked_at.desc())
        .limit(5)
    )
    rows = result.all()

    return {
        "achievements": [
            {
                "code": a.code,
                "name": a.name,
                "icon": a.icon,
                "reward_exp": a.reward_exp,
                "unlocked_at": ca.unlocked_at.isoformat(),
            }
            for ca, a in rows
        ]
    }
