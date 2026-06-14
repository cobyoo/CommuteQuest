from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.deps import get_current_user
from core.game_engine import get_job_class, calculate_level
from models.database import get_db
from models.character import Character
from models.user import User
from schemas.character import CharacterCreateRequest, CharacterResponse

router = APIRouter()


@router.post("/", response_model=CharacterResponse, status_code=201)
async def create_character(
    req: CharacterCreateRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(select(Character).where(Character.user_id == user.id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="이미 캐릭터가 존재합니다")

    character = Character(user_id=user.id, name=req.name)
    db.add(character)
    await db.commit()
    await db.refresh(character)
    return character


@router.get("/me", response_model=CharacterResponse)
async def get_my_character(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터를 먼저 생성해주세요")
    return character
