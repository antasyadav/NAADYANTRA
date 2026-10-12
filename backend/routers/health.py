from fastapi import APIRouter, Depends
from datetime import datetime, timezone
from sqlalchemy.orm import Session
from sqlalchemy import text

from backend.database import get_db
from backend.schemas import HealthResponse, ReadyResponse, SystemInfoResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse)
async def health_check():
    """Basic liveness check."""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(timezone.utc)
    )


@router.get("/ready", response_model=ReadyResponse)
async def readiness_check(db: Session = Depends(get_db)):
    """Check database and service readiness."""
    try:
        # Try to execute a simple query
        db.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception:
        db_status = "disconnected"
    
    return ReadyResponse(
        status="ready" if db_status == "connected" else "not_ready",
        database=db_status,
        timestamp=datetime.now(timezone.utc)
    )


@router.get("/api/v1/system/info", response_model=SystemInfoResponse)
async def system_info():
    """Return API version, application version, environment and server UTC time."""
    return SystemInfoResponse(
        api_version="1.0.0",
        application_version="1.0.0",
        environment="development",  # This should come from settings
        server_utc=datetime.now(timezone.utc)
    )
