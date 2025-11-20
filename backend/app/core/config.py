from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = "development"
    
    # Database
    DATABASE_URL: str
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3000",
    ]
    
    # External APIs
    OPENROUTE_API_KEY: str = ""
    NOMINATIM_EMAIL: str = "dev@smartblink.local"
    OSRM_URL: str = "http://localhost:5000"
    
    # ML
    ENABLE_ML_CACHE: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
