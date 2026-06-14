# Import all models so SQLAlchemy metadata picks them up
from models.user import User  # noqa: F401
from models.character import Character, CommuteLog  # noqa: F401
from models.guild import Guild, GuildMember  # noqa: F401
from models.achievement import Achievement, CharacterAchievement  # noqa: F401
