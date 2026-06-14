from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.deps import get_current_user
from models.database import get_db
from models.character import Character
from models.equipment import Equipment, CharacterEquipment
from models.user import User

router = APIRouter()


@router.get("/shop")
async def list_shop(db: AsyncSession = Depends(get_db)):
    """상점 — 구매 가능한 장비 목록"""
    result = await db.execute(
        select(Equipment).where(Equipment.price > 0).order_by(Equipment.slot, Equipment.price)
    )
    equipments = result.scalars().all()

    return {
        "items": [
            {
                "code": e.code,
                "name": e.name,
                "description": e.description,
                "icon": e.icon,
                "slot": e.slot,
                "rarity": e.rarity,
                "price": e.price,
                "stats": _format_stats(e),
                "unlock_condition": e.unlock_condition,
            }
            for e in equipments
        ]
    }


@router.post("/buy/{equipment_code}")
async def buy_equipment(
    equipment_code: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """장비 구매"""
    # 캐릭터 조회
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다")

    # 장비 조회
    result = await db.execute(select(Equipment).where(Equipment.code == equipment_code))
    equipment = result.scalar_one_or_none()
    if not equipment:
        raise HTTPException(status_code=404, detail="존재하지 않는 장비입니다")

    # 이미 보유 체크 (소모품 제외)
    if equipment.slot != "consumable":
        result = await db.execute(
            select(CharacterEquipment).where(
                CharacterEquipment.character_id == character.id,
                CharacterEquipment.equipment_id == equipment.id,
            )
        )
        if result.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="이미 보유한 장비입니다")

    # 골드(EXP) 차감 — MVP에서는 total_exp를 화폐로 사용
    if character.total_exp < equipment.price:
        raise HTTPException(
            status_code=400,
            detail=f"EXP가 부족합니다 (보유: {character.total_exp}, 필요: {equipment.price})"
        )

    character.total_exp -= equipment.price

    # 장비 지급
    char_equip = CharacterEquipment(
        character_id=character.id,
        equipment_id=equipment.id,
    )
    db.add(char_equip)
    await db.commit()

    return {
        "message": f"'{equipment.name}' 구매 완료!",
        "remaining_exp": character.total_exp,
        "item": {
            "code": equipment.code,
            "name": equipment.name,
            "icon": equipment.icon,
        },
    }


@router.get("/inventory")
async def get_inventory(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """내 인벤토리 (보유 장비 목록)"""
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다")

    result = await db.execute(
        select(CharacterEquipment, Equipment)
        .join(Equipment, CharacterEquipment.equipment_id == Equipment.id)
        .where(CharacterEquipment.character_id == character.id)
        .order_by(Equipment.slot, CharacterEquipment.is_equipped.desc())
    )
    rows = result.all()

    items = []
    for ce, e in rows:
        items.append({
            "code": e.code,
            "name": e.name,
            "icon": e.icon,
            "slot": e.slot,
            "rarity": e.rarity,
            "is_equipped": ce.is_equipped,
            "stats": _format_stats(e),
        })

    return {"inventory": items, "total": len(items)}


@router.post("/equip/{equipment_code}")
async def equip_item(
    equipment_code: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """장비 장착 (같은 슬롯의 기존 장비는 자동 해제)"""
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다")

    # 보유 확인
    result = await db.execute(
        select(CharacterEquipment, Equipment)
        .join(Equipment, CharacterEquipment.equipment_id == Equipment.id)
        .where(
            CharacterEquipment.character_id == character.id,
            Equipment.code == equipment_code,
        )
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="보유하지 않은 장비입니다")

    char_equip, equipment = row

    if equipment.slot == "consumable":
        raise HTTPException(status_code=400, detail="소모품은 장착할 수 없습니다")

    # 같은 슬롯 기존 장비 해제
    result = await db.execute(
        select(CharacterEquipment)
        .join(Equipment, CharacterEquipment.equipment_id == Equipment.id)
        .where(
            CharacterEquipment.character_id == character.id,
            Equipment.slot == equipment.slot,
            CharacterEquipment.is_equipped == True,
        )
    )
    for existing in result.scalars().all():
        existing.is_equipped = False

    # 장착
    char_equip.is_equipped = True

    # 스탯 적용 (간단 버전: 장착 시 캐릭터 스탯에 반영)
    _apply_equipment_stats(character, equipment)

    await db.commit()

    return {
        "message": f"'{equipment.name}' 장착 완료!",
        "equipped": {
            "code": equipment.code,
            "name": equipment.name,
            "icon": equipment.icon,
            "slot": equipment.slot,
        },
    }


@router.post("/unequip/{equipment_code}")
async def unequip_item(
    equipment_code: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """장비 해제"""
    result = await db.execute(select(Character).where(Character.user_id == user.id))
    character = result.scalar_one_or_none()
    if not character:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다")

    result = await db.execute(
        select(CharacterEquipment, Equipment)
        .join(Equipment, CharacterEquipment.equipment_id == Equipment.id)
        .where(
            CharacterEquipment.character_id == character.id,
            Equipment.code == equipment_code,
            CharacterEquipment.is_equipped == True,
        )
    )
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="장착된 장비가 아닙니다")

    char_equip, equipment = row
    char_equip.is_equipped = False

    # 스탯 제거
    _remove_equipment_stats(character, equipment)

    await db.commit()

    return {"message": f"'{equipment.name}' 해제 완료!"}


def _apply_equipment_stats(character: Character, equipment: Equipment):
    character.hp = min(character.hp + equipment.hp_bonus, character.max_hp + equipment.hp_bonus)
    character.max_hp += equipment.hp_bonus
    character.mp += equipment.mp_bonus
    character.speed += equipment.speed_bonus
    character.luck += equipment.luck_bonus


def _remove_equipment_stats(character: Character, equipment: Equipment):
    character.max_hp -= equipment.hp_bonus
    character.hp = min(character.hp, character.max_hp)
    character.mp -= equipment.mp_bonus
    character.speed -= equipment.speed_bonus
    character.luck -= equipment.luck_bonus


def _format_stats(e: Equipment) -> dict:
    stats = {}
    if e.hp_bonus != 0:
        stats["HP"] = f"{'+' if e.hp_bonus > 0 else ''}{e.hp_bonus}"
    if e.mp_bonus != 0:
        stats["MP"] = f"{'+' if e.mp_bonus > 0 else ''}{e.mp_bonus}"
    if e.speed_bonus != 0:
        stats["SPD"] = f"{'+' if e.speed_bonus > 0 else ''}{e.speed_bonus}"
    if e.luck_bonus != 0:
        stats["LUCK"] = f"{'+' if e.luck_bonus > 0 else ''}{e.luck_bonus}"
    if e.exp_multiplier != 1.0:
        stats["EXP"] = f"x{e.exp_multiplier}"
    return stats
