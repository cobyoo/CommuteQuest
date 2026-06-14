from datetime import datetime, timezone

from sqlalchemy import String, Integer, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Equipment(Base):
    """장비 정의 테이블"""
    __tablename__ = "equipments"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(String(255))
    icon: Mapped[str] = mapped_column(String(10))
    slot: Mapped[str] = mapped_column(String(20))  # head, body, accessory, consumable
    rarity: Mapped[str] = mapped_column(String(20))  # common, uncommon, rare, epic, legendary
    hp_bonus: Mapped[int] = mapped_column(Integer, default=0)
    mp_bonus: Mapped[int] = mapped_column(Integer, default=0)
    speed_bonus: Mapped[int] = mapped_column(Integer, default=0)
    luck_bonus: Mapped[int] = mapped_column(Integer, default=0)
    exp_multiplier: Mapped[float] = mapped_column(default=1.0)  # 경험치 추가 배율
    unlock_condition: Mapped[str | None] = mapped_column(String(100), nullable=True)
    price: Mapped[int] = mapped_column(Integer, default=0)  # 상점 가격 (0 = 비매품)


class CharacterEquipment(Base):
    """캐릭터 보유 장비"""
    __tablename__ = "character_equipments"

    id: Mapped[int] = mapped_column(primary_key=True)
    character_id: Mapped[int] = mapped_column(ForeignKey("characters.id"), index=True)
    equipment_id: Mapped[int] = mapped_column(ForeignKey("equipments.id"))
    is_equipped: Mapped[bool] = mapped_column(Boolean, default=False)
    acquired_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
