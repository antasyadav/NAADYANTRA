from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from typing import Optional

from backend.database import get_db, AuditLog, Event, Session as DBSession, Device, Trainee, IngestionError
from backend.auth import get_current_admin
from backend.schemas import AuditLogResponse, DiagnosticsIngestionResponse, DiagnosticsDatabaseResponse, PaginatedResponse

router = APIRouter()


@router.get("/api/v1/audit-logs", response_model=PaginatedResponse)
async def list_audit_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(100, ge=1, le=500),
    user: Optional[str] = None,
    action: Optional[str] = None,
    resource_type: Optional[str] = None,
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Restricted, paginated administrative and trainer audit history."""
    query = db.query(AuditLog)
    
    if user:
        query = query.filter(AuditLog.user == user)
    
    if action:
        query = query.filter(AuditLog.action.ilike(f"%{action}%"))
    
    if resource_type:
        query = query.filter(AuditLog.resource_type == resource_type)
    
    total = query.count()
    logs = query.order_by(AuditLog.timestamp.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[AuditLogResponse.model_validate(l) for l in logs]
    )


@router.get("/api/v1/diagnostics/ingestion", response_model=DiagnosticsIngestionResponse)
async def ingestion_diagnostics(
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Restricted operational counts for accepted events, duplicates, validation failures and server errors."""
    accepted_events = db.query(Event).filter(Event.ingestion_status == "accepted").count()
    duplicate_events = db.query(Event).filter(Event.ingestion_status == "duplicate").count()
    
    validation_failures = db.query(IngestionError).filter(
        IngestionError.error_type == "validation_error"
    ).count()
    
    server_errors = db.query(IngestionError).filter(
        IngestionError.error_type == "database_error"
    ).count()
    
    total_processed = accepted_events + duplicate_events + validation_failures + server_errors
    
    return DiagnosticsIngestionResponse(
        accepted_events=accepted_events,
        duplicate_events=duplicate_events,
        validation_failures=validation_failures,
        server_errors=server_errors,
        total_processed=total_processed
    )


@router.get("/api/v1/diagnostics/database", response_model=DiagnosticsDatabaseResponse)
async def database_diagnostics(
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Restricted database health/metadata without leaking credentials or sensitive connection strings."""
    from sqlalchemy import inspect
    
    inspector = inspect(db.bind)
    table_names = inspector.get_table_names()
    
    return DiagnosticsDatabaseResponse(
        database_status="connected",
        total_tables=len(table_names),
        total_events=db.query(Event).count(),
        total_sessions=db.query(DBSession).count(),
        total_devices=db.query(Device).count(),
        total_trainees=db.query(Trainee).count()
    )
