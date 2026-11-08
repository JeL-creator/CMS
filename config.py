import os
from datetime import timedelta
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
ROOT = Path(__file__).resolve().parent

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-only-change-me-before-use")
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", f"sqlite:///{ROOT / 'instance' / 'egmis.db'}")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {"pool_pre_ping": True}
    WTF_CSRF_TIME_LIMIT = 3600
    PERMANENT_SESSION_LIFETIME = timedelta(seconds=int(os.getenv("SESSION_LIFETIME_SECONDS", "28800")))
    SESSION_REFRESH_EACH_REQUEST = True
    REMEMBER_COOKIE_DURATION = timedelta(seconds=int(os.getenv("REMEMBER_COOKIE_SECONDS", "28800")))
    MAX_CONTENT_LENGTH = 128 * 1024 * 1024  # Full ZIP restore limit (128 MiB); JSON endpoint enforces 64 MiB itself
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    SESSION_COOKIE_SECURE = os.getenv("SESSION_COOKIE_SECURE", "0") == "1"
    REMEMBER_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_SAMESITE = "Lax"
    SCHOOL_NAME = os.getenv("SCHOOL_NAME", "EGMIS School System")
    RATELIMIT_STORAGE_URI = os.getenv("RATELIMIT_STORAGE_URI", "memory://")
