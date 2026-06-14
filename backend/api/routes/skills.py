from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.deps import get_current_user
from core.skills import SKILL_DEFINITIONS
from models.database import get_db
from models.character import Character
from models.user import User

router = APIRouter()


@router.get("/")
async def get_my_skills(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """내 캐릭터가 사용 가능한 스킬 목록"""
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다")

    available = []
    locked = []

    for skill in SKILL_DEFINITIONS:
        skill_info = {
            "code": skill["code"],
            "name": skill["name"],
            "description": skill["description"],
            "icon": skill["icon"],
            "job_class": skill["job_class"],
            "level_required": skill["level_required"],
            "cooldown_hours": skill["cooldown_hours"],
        }

        if character.level >= skill["level_required"]:
            skill_info["unlocked"] = True
            available.append(skill_info)
        else:
            skill_info["unlocked"] = False
            locked.append(skill_info)

    return {
        "available": available,
        "locked": locked,
        "total_skills": len(SKILL_DEFINITIONS),
        "unlocked_count": len(available),
    }
