from datetime import datetime, timezone

from sqlalchemy import String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from models.database import Base


class Guild(Base):
    __tablename__ = "guilds"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(50), unique=True)
    route_name: Mapped[str] = mapped_column(String(100))  # 예: "2호선", "9호선 급행"
    leader_id: Mapped[int] = mapped_column(ForeignKey("characters.id"))
    member_count: Mapped[int] = mapped_column(Integer, default=1)
    total_boss_clears: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )


class GuildMember(Base):
    __tablename__ = "guild_members"

    id: Mapped[int] = mapped_column(primary_key=True)
    guild_id: Mapped[int] = mapped_column(ForeignKey("guilds.id"), index=True)
    character_id: Mapped[int] = mapped_column(ForeignKey("characters.id"), unique=True)
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
