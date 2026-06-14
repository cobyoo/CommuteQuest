from datetime import datetime, timezone

from sqlalchemy import String, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from models.database import Base


class Character(Base):
    __tablename__ = "characters"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True)
    name: Mapped[str] = mapped_column(String(50))
    job_class: Mapped[str] = mapped_column(String(20), default="intern")
    level: Mapped[int] = mapped_column(Integer, default=1)
    total_exp: Mapped[int] = mapped_column(Integer, default=0)
    hp: Mapped[int] = mapped_column(Integer, default=100)
    max_hp: Mapped[int] = mapped_column(Integer, default=100)
    mp: Mapped[int] = mapped_column(Integer, default=50)  # 인내력
    speed: Mapped[int] = mapped_column(Integer, default=10)
    luck: Mapped[int] = mapped_column(Integer, default=5)
    streak_days: Mapped[int] = mapped_column(Integer, default=0)  # 연속 출근일
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    user: Mapped["User"] = relationship(back_populates="character")
    commute_logs: Mapped[list["CommuteLog"]] = relationship(back_populates="character")


class CommuteLog(Base):
    __tablename__ = "commute_logs"

    id: Mapped[int] = mapped_column(primary_key=True)
    character_id: Mapped[int] = mapped_column(ForeignKey("characters.id"), index=True)
    dungeon_grade: Mapped[str] = mapped_column(String(20))
    commute_minutes: Mapped[int] = mapped_column(Integer)
    exp_earned: Mapped[int] = mapped_column(Integer)
    boss_cleared: Mapped[bool] = mapped_column(default=False)
    hp_penalty: Mapped[int] = mapped_column(Integer, default=0)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    arrived_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    character: Mapped["Character"] = relationship(back_populates="commute_logs")
