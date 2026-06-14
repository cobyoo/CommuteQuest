"""장비 데이터 시드 스크립트"""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.equipments import EQUIPMENT_DEFINITIONS
from models.equipment import Equipment


async def seed_equipments(db: AsyncSession) -> int:
    """장비 정의를 DB에 삽입 (이미 존재하면 스킵)"""
    inserted = 0
    for defn in EQUIPMENT_DEFINITIONS:
        result = await db.execute(
            select(Equipment).where(Equipment.code == defn["code"])
        )
        if result.scalar_one_or_none():
            continue

        equipment = Equipment(**defn)
        db.add(equipment)
        inserted += 1

    await db.commit()
    return inserted
