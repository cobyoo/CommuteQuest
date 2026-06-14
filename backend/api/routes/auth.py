from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import hash_password, verify_password, create_access_token
from models.database import get_db
from models.user import User
from schemas.auth import SignUpRequest, LoginRequest, TokenResponse

router = APIRouter()


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def signup(req: SignUpRequest, db: AsyncSession = Depends(get_db)):
    # 중복 체크
    existing = await db.execute(select(User).where(User.email == req.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="이미 가입된 이메일입니다")

    existing_nick = await db.execute(select(User).where(User.nickname == req.nickname))
    if existing_nick.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="이미 사용 중인 닉네임입니다")

    user = User(
        email=req.email,
        hashed_password=hash_password(req.password),
        nickname=req.nickname,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(user.id)
    return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(req.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="이메일 또는 비밀번호가 올바르지 않습니다")

    token = create_access_token(user.id)
    return TokenResponse(access_token=token)
