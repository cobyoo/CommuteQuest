from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from api.routes import auth, characters, commute, dungeons, guilds, rankings, achievements, equipments, skills
from core.config import settings
from models.database import init_db, async_session
from services.seed_achievements import seed_achievements
from services.seed_equipments import seed_equipments


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    async with async_session() as db:
        await seed_achievements(db)
        await seed_equipments(db)
    yield


app = FastAPI(
    title="CommuteQuest API",
    description="출퇴근 RPG 게임 백엔드",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["인증"])
app.include_router(characters.router, prefix="/api/v1/characters", tags=["캐릭터"])
app.include_router(commute.router, prefix="/api/v1/commute", tags=["출퇴근"])
app.include_router(dungeons.router, prefix="/api/v1/dungeons", tags=["던전"])
app.include_router(guilds.router, prefix="/api/v1/guilds", tags=["길드"])
app.include_router(rankings.router, prefix="/api/v1/rankings", tags=["랭킹"])
app.include_router(achievements.router, prefix="/api/v1/achievements", tags=["업적"])
app.include_router(equipments.router, prefix="/api/v1/equipments", tags=["장비"])
app.include_router(skills.router, prefix="/api/v1/skills", tags=["스킬"])


@app.get("/health")
async def health_check():
    return {"status": "alive", "quest": "ongoing"}
