from pydantic import BaseModel


class CharacterCreateRequest(BaseModel):
    name: str


class CharacterResponse(BaseModel):
    id: int
    name: str
    job_class: str
    level: int
    total_exp: int
    hp: int
    max_hp: int
    mp: int
    speed: int
    luck: int
    streak_days: int

    class Config:
        from_attributes = True
