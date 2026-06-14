from datetime import datetime

from pydantic import BaseModel


class CommuteStartRequest(BaseModel):
    dungeon_grade: str  # hell, hard, normal, field, bonus
    target_arrival: datetime  # 목표 도착 시간 (출근 시간)


class CommuteEndRequest(BaseModel):
    arrived_at: datetime


class CommuteResultResponse(BaseModel):
    commute_minutes: int
    dungeon_grade: str
    exp_earned: int
    boss_cleared: bool
    hp_penalty: int
    level_up: bool
    new_level: int
    job_promoted: bool
    new_job: str | None = None
