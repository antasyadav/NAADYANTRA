from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import Optional, List
import csv
from io import StringIO

from backend.database import get_db, Session as DBSession, Event, SessionSummary
from backend.auth import get_current_trainer_or_admin
from backend.schemas import (
    SessionResponse, SessionUpdateRequest, EventResponse,
    SessionSummaryResponse, PaginatedResponse
)

router = APIRouter()


@router.get("/api/v1/sessions", response_model=PaginatedResponse)
async def list_sessions(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    device_id: Optional[str] = None,
    trainee_id: Optional[str] = None,
    status: Optional[str] = None,  # active, completed
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Paginated session listing with filters."""
    query = db.query(DBSession)
    
    if device_id:
        query = query.filter(DBSession.device_id == device_id)
    
    if trainee_id:
        query = query.filter(DBSession.trainee_id == trainee_id)
    
    if status == "active":
        query = query.filter(DBSession.ended_at.is_(None))
    elif status == "completed":
        query = query.filter(DBSession.ended_at.isnot(None))
    
    if date_from:
        query = query.filter(DBSession.started_at >= date_from)
    
    if date_to:
        query = query.filter(DBSession.started_at <= date_to)
    
    total = query.count()
    sessions = query.order_by(DBSession.started_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[SessionResponse.model_validate(s) for s in sessions]
    )


@router.get("/api/v1/sessions/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: int,
    device_id: Optional[str] = Query(None),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Session metadata, device, trainee, duration, event counts and summary."""
    query = db.query(DBSession).filter(DBSession.id == session_id)
    
    # Add device filter if provided to handle session ID collisions
    if device_id:
        query = query.filter(DBSession.device_id == device_id)
    
    session = query.first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    return session


@router.get("/api/v1/sessions/{session_id}/events", response_model=PaginatedResponse)
async def get_session_events(
    session_id: int,
    device_id: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(100, ge=1, le=500),
    event: Optional[str] = None,
    cause: Optional[str] = None,
    alert: Optional[str] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Chronological event timeline with pagination and event/cause/alert filters."""
    # First find the session
    session_query = db.query(DBSession).filter(DBSession.id == session_id)
    if device_id:
        session_query = session_query.filter(DBSession.device_id == device_id)
    
    session = session_query.first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # Query events for this session
    query = db.query(Event).filter(Event.internal_session_id == session_id)
    
    if event:
        query = query.filter(Event.event_name == event)
    
    if cause:
        query = query.filter(Event.cause == cause)
    
    if alert:
        query = query.filter(Event.alert == alert)
    
    total = query.count()
    events = query.order_by(Event.server_timestamp.asc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[EventResponse.model_validate(e) for e in events]
    )


@router.get("/api/v1/sessions/{session_id}/summary", response_model=SessionSummaryResponse)
async def get_session_summary(
    session_id: int,
    device_id: Optional[str] = Query(None),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Stored firmware summary and backend-derived counts."""
    # First find the session
    session_query = db.query(DBSession).filter(DBSession.id == session_id)
    if device_id:
        session_query = session_query.filter(DBSession.device_id == device_id)
    
    session = session_query.first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    summary = db.query(SessionSummary).filter(SessionSummary.session_id == session_id).first()
    if not summary:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Summary not found for this session"
        )
    
    return summary


@router.get("/api/v1/sessions/{session_id}/export")
async def export_session(
    session_id: int,
    device_id: Optional[str] = Query(None),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """CSV export of session events and summary with correct escaping and access control."""
    # First find the session
    session_query = db.query(DBSession).filter(DBSession.id == session_id)
    if device_id:
        session_query = session_query.filter(DBSession.device_id == device_id)
    
    session = session_query.first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # Get events
    events = db.query(Event).filter(Event.internal_session_id == session_id).order_by(Event.server_timestamp.asc()).all()
    
    # Get summary
    summary = db.query(SessionSummary).filter(SessionSummary.session_id == session_id).first()
    
    # Create CSV
    output = StringIO()
    writer = csv.writer(output)
    
    # Write header
    writer.writerow([
        "timestamp", "device_id", "trainee_id", "event_name", "alert", "cause",
        "model_label", "leak_probability", "rms", "gas_delta", "gas_ratio",
        "temperature", "uv_delta", "wet", "device_uptime_ms"
    ])
    
    # Write events
    for event in events:
        writer.writerow([
            event.server_timestamp.isoformat() if event.server_timestamp else "",
            event.device_id,
            event.trainee_id,
            event.event_name or "",
            event.alert or "",
            event.cause or "",
            event.model_label or "",
            event.leak_probability or "",
            event.rms or "",
            event.gas_delta or "",
            event.gas_ratio or "",
            event.temperature or "",
            event.uv_delta or "",
            event.wet or "",
            event.device_uptime_ms or ""
        ])
    
    # Write summary as separate section
    if summary:
        writer.writerow([])
        writer.writerow(["SUMMARY"])
        writer.writerow([
            "device_id", "trainee_id", "duration_seconds", "windows",
            "leak_events", "gas_events", "wet_events", "heat_events",
            "uv_events", "noise_windows", "max_leak_probability"
        ])
        writer.writerow([
            summary.device_id,
            summary.trainee_id,
            summary.duration_seconds or "",
            summary.windows or "",
            summary.leak_events or "",
            summary.gas_events or "",
            summary.wet_events or "",
            summary.heat_events or "",
            summary.uv_events or "",
            summary.noise_windows or "",
            summary.max_leak_probability or ""
        ])
    
    csv_content = output.getvalue()
    
    return {
        "content_type": "text/csv",
        "filename": f"session_{session_id}_export.csv",
        "data": csv_content
    }


@router.patch("/api/v1/sessions/{session_id}", response_model=SessionResponse)
async def update_session(
    session_id: int,
    request: SessionUpdateRequest,
    device_id: Optional[str] = Query(None),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Update permitted session metadata or trainer notes without rewriting the original device evidence."""
    query = db.query(DBSession).filter(DBSession.id == session_id)
    if device_id:
        query = query.filter(DBSession.device_id == device_id)
    
    session = query.first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    if request.trainer_notes is not None:
        session.trainer_notes = request.trainer_notes
    
    if request.session_metadata is not None:
        session.session_metadata = request.session_metadata
    
    db.commit()
    db.refresh(session)
    
    return session
