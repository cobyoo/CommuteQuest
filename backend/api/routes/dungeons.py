from fastapi import APIRouter

from core.game_engine import DungeonGrade, DUNGEON_MULTIPLIER

router = APIRouter()


DUNGEON_INFO = {
    DungeonGrade.HELL: {"name": "2호선", "emoji": "🔴", "description": "지옥의 순환선"},
    DungeonGrade.HARD: {"name": "9호선 급행", "emoji": "🟠", "description": "급행의 압박"},
    DungeonGrade.NORMAL: {"name": "신분당선", "emoji": "🟡", "description": "쾌적한 노말 던전"},
    DungeonGrade.FIELD: {"name": "버스", "emoji": "🟢", "description": "필드 몬스터 출몰"},
    DungeonGrade.BONUS: {"name": "도보/자전거", "emoji": "🔵", "description": "체력 보너스 던전"},
}


@router.get("/")
async def list_dungeons():
    """사용 가능한 던전(노선) 목록"""
    dungeons = []
    for grade in DungeonGrade:
        info = DUNGEON_INFO[grade]
        dungeons.append({
            "grade": grade.value,
            "name": info["name"],
            "emoji": info["emoji"],
            "description": info["description"],
            "exp_multiplier": DUNGEON_MULTIPLIER[grade],
        })
    return {"dungeons": dungeons}
