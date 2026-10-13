from fastapi import FastAPI, Request, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import logging
import os
import uvicorn

from backend.config import settings
from backend.database import engine, Base, get_db
from backend.routers import health, ingestion, devices, sessions, trainees, events, auth, assessments, dashboard, audit

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup and shutdown events."""
    # Startup
    logger.info("Starting NAADYANTRA backend...")
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created/verified")
    except Exception as e:
        logger.error(f"Failed to create database tables: {e}")
        raise
    
    yield
    
    # Shutdown
    logger.info("Shutting down NAADYANTRA backend...")


# Create FastAPI app
app = FastAPI(
    title="NAADYANTRA Backend",
    description="Backend for ESP32-based diagnostic sensing and vocational training platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Include routers
app.include_router(health.router)
app.include_router(ingestion.router)
app.include_router(devices.router)
app.include_router(sessions.router)
app.include_router(trainees.router)
app.include_router(events.router)
app.include_router(auth.router)
app.include_router(assessments.router)
app.include_router(dashboard.router)
app.include_router(audit.router)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


# Root endpoint
@app.get("/")
async def root():
    return {
        "name": "NAADYANTRA Backend",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }


if __name__ == "__main__":
    port = int(os.environ.get("PORT", settings.server_port))
    uvicorn.run(
        "backend.main:app",
        host="0.0.0.0",
        port=port,
        reload=settings.environment == "development"
    )
