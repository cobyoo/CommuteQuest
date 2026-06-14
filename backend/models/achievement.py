from datetime import datetime, timezone

from sqlalchemy import String, Integer, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Achievement(Base):
    """업적 정의 테이블"""
    __tablename__ = "achievements"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(String(255))
    icon: Mapped[str] = mapped_column(String(10))  # emoji
    category: Mapped[str] = mapped_column(String(30))  # streak, boss, commute, special
    condition_type: Mapped[str] = mapped_column(String(30))  # streak_days, boss_clears, total_commutes, level
    condition_value: Mapped[int] = mapped_column(Integer)
    reward_exp: Mapped[int] = mapped_column(Integer, default=0)
    reward_title: Mapped[str | None] = mapped_column(String(50), nullable=True)
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)


class CharacterAchievement(Base):
    """캐릭터가 달성한 업적"""
    __tablename__ = "character_achievements"

    id: Mapped[int] = mapped_column(primary_key=True)
    character_id: Mapped[int] = mapped_column(ForeignKey("characters.id"), index=True)
    achievement_id: Mapped[int] = mapped_column(ForeignKey("achievements.id"))
    unlocked_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
