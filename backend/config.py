from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    database_url: str = "sqlite:///./naadyantra.db"
    server_host: str = "0.0.0.0"
    server_port: int = 8000
    environment: str = "development"
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    device_key_hash: str
    device_online_threshold_seconds: int = 300

    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
