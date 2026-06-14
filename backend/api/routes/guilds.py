from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.deps import get_current_user
from models.database import get_db
from models.guild import Guild
from models.user import User

router = APIRouter()


@router.get("/")
async def list_guilds(db: AsyncSession = Depends(get_db)):
    """길드 목록 조회"""
    result = await db.execute(select(Guild).order_by(Guild.total_boss_clears.desc()).limit(20))
    guilds = result.scalars().all()
    return {"guilds": [{"id": g.id, "name": g.name, "route": g.route_name, "members": g.member_count} for g in guilds]}
