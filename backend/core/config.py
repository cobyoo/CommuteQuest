from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "CommuteQuest"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/commutequest"

    @property
    def async_database_url(self) -> str:
        """Railway provides postgresql:// but asyncpg needs postgresql+asyncpg://"""
        url = self.DATABASE_URL
        if url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        return url

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # JWT
    SECRET_KEY: str = "change-me-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7일

    # 게임 밸런스
    BASE_EXP_PER_MINUTE: int = 10
    BOSS_CLEAR_BONUS: int = 500
    LATE_HP_PENALTY: int = 20

    class Config:
        env_file = ".env"


settings = Settings()
