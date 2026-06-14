from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.deps import get_current_user
from core.game_engine import (
    DungeonGrade,
    calculate_exp,
    calculate_level,
    get_job_class,
    check_boss_clear,
    calculate_late_penalty,
)
from models.database import get_db
from models.character import Character, CommuteLog
from models.user import User
from schemas.commute import CommuteStartRequest, CommuteEndRequest, CommuteResultResponse
from core.random_events import roll_random_event
from services.achievement_service import check_achievements

router = APIRouter()


@router.post("/start")
async def start_commute(
    req: CommuteStartRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """출근 시작 기록"""
    return {"status": "commute_started", "dungeon_grade": req.dungeon_grade}


@router.post("/end", response_model=CommuteResultResponse)
async def end_commute(
    req: CommuteEndRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """출근 완료 — 경험치 계산, 보스 판정, 레벨업 체크"""
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다")

    # TODO: commute_start 세션에서 시작 시간/던전 정보 가져오기 (MVP에선 클라이언트 전달)
    dungeon_grade = DungeonGrade.NORMAL  # placeholder
    commute_minutes = 45  # placeholder

    # 경험치 계산
    exp_earned = calculate_exp(commute_minutes, dungeon_grade)
    old_level = character.level

    # 보스 클리어 판정
    boss_cleared = True  # placeholder: 정시 도착 여부
    if boss_cleared:
        from core.config import settings
        exp_earned += settings.BOSS_CLEAR_BONUS

    # HP 페널티
    hp_penalty = 0
    if not boss_cleared:
        hp_penalty = calculate_late_penalty(5)  # placeholder
        character.hp = max(0, character.hp - hp_penalty)

    # 경험치 & 레벨업
    character.total_exp += exp_earned
    character.level = calculate_level(character.total_exp)
    level_up = character.level > old_level

    # 직업 전직
    old_job = character.job_class
    new_job = get_job_class(character.level)
    job_promoted = new_job.value != old_job
    if job_promoted:
        character.job_class = new_job.value

    # 연속 출근
    character.streak_days += 1

    # 로그 저장
    log = CommuteLog(
        character_id=character.id,
        dungeon_grade=dungeon_grade.value,
        commute_minutes=commute_minutes,
        exp_earned=exp_earned,
        boss_cleared=boss_cleared,
        hp_penalty=hp_penalty,
        started_at=req.arrived_at,  # placeholder
        arrived_at=req.arrived_at,
    )
    # 랜덤 이벤트 발생
    event = roll_random_event(luck=character.luck)
    event_data = None
    if event:
        effect = event["effect"]
        if "exp_bonus" in effect:
            exp_earned += effect["exp_bonus"]
            character.total_exp += effect["exp_bonus"]
        if "hp_recovery" in effect:
            character.hp = min(character.hp + effect["hp_recovery"], character.max_hp)
        if "hp_damage" in effect:
            character.hp = max(0, character.hp - effect["hp_damage"])
        if "mp_recovery" in effect:
            character.mp = min(character.mp + effect["mp_recovery"], 100)
        if "mp_damage" in effect:
            character.mp = max(0, character.mp - effect["mp_damage"])
        event_data = {
            "name": event["name"],
            "description": event["description"],
            "icon": event["icon"],
            "type": event["type"],
        }

    db.add(log)
    await db.commit()

    # 업적 체크
    new_achievements = await check_achievements(db, character)

    return CommuteResultResponse(
        commute_minutes=commute_minutes,
        dungeon_grade=dungeon_grade.value,
        exp_earned=exp_earned,
        boss_cleared=boss_cleared,
        hp_penalty=hp_penalty,
        level_up=level_up,
        new_level=character.level,
        job_promoted=job_promoted,
        new_job=new_job.value if job_promoted else None,
        achievements_unlocked=new_achievements,
        random_event=event_data,
    )
