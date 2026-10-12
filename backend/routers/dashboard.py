from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, text
from datetime import datetime, timezone, timedelta
from typing import Optional

from backend.database import get_db, Session as DBSession, Event, Device, Trainee, IngestionError
from backend.auth import get_current_trainer_or_admin
from backend.schemas import (
    DashboardOverviewResponse, DashboardRecentActivityItem,
    DashboardTrendsResponse, DashboardDeviceHealthResponse,
    DashboardAlertResponse, PaginatedResponse
)

router = APIRouter()


@router.get("/api/v1/dashboard/overview", response_model=DashboardOverviewResponse)
async def dashboard_overview(
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Recorded sessions, recent activity, device counts and event counts."""
    total_sessions = db.query(DBSession).count()
    total_devices = db.query(Device).count()
    total_trainees = db.query(Trainee).count()
    total_events = db.query(Event).count()
    
    # Recent sessions (last 24 hours)
    recent_threshold = datetime.now(timezone.utc) - timedelta(hours=24)
    recent_sessions_count = db.query(DBSession).filter(
        DBSession.started_at >= recent_threshold
    ).count()
    
    # Active devices (seen in last 5 minutes)
    online_threshold = datetime.now(timezone.utc) - timedelta(minutes=5)
    active_devices_count = db.query(Device).filter(
        Device.last_seen_at >= online_threshold,
        Device.is_active == True
    ).count()
    
    return DashboardOverviewResponse(
        total_sessions=total_sessions,
        total_devices=total_devices,
        total_trainees=total_trainees,
        total_events=total_events,
        recent_sessions_count=recent_sessions_count,
        active_devices_count=active_devices_count
    )


@router.get("/api/v1/dashboard/recent-activity", response_model=PaginatedResponse)
async def recent_activity(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Recent sessions and events with pagination."""
    activities = []
    
    # Get recent sessions
    recent_sessions = db.query(DBSession).order_by(
        DBSession.started_at.desc()
    ).limit(page_size).all()
    
    for session in recent_sessions:
        activities.append(DashboardRecentActivityItem(
            type="session",
            timestamp=session.started_at,
            device_id=session.device_id,
            trainee_id=session.trainee_id,
            details={
                "session_id": session.session_id,
                "status": "active" if not session.ended_at else "completed"
            }
        ))
    
    # Get recent events (especially alerts)
    recent_events = db.query(Event).filter(
        Event.alert.in_(["DANGER", "CAUTION"])
    ).order_by(Event.server_timestamp.desc()).limit(page_size).all()
    
    for event in recent_events:
        activities.append(DashboardRecentActivityItem(
            type="alert",
            timestamp=event.server_timestamp,
            device_id=event.device_id,
            trainee_id=event.trainee_id,
            details={
                "event_name": event.event_name,
                "alert": event.alert,
                "cause": event.cause
            }
        ))
    
    # Sort by timestamp
    activities.sort(key=lambda x: x.timestamp, reverse=True)
    
    # Paginate
    total = len(activities)
    start = (page - 1) * page_size
    end = start + page_size
    paginated_activities = activities[start:end]
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=paginated_activities
    )


@router.get("/api/v1/dashboard/trends", response_model=list[DashboardTrendsResponse])
async def dashboard_trends(
    bucket: str = Query("hour", pattern="^(hour|day|week)$"),
    days: int = Query(7, ge=1, le=365),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Clearly defined time-bucketed session/event counts."""
    from_date = datetime.now(timezone.utc) - timedelta(days=days)
    
    # Determine bucket interval
    if bucket == "hour":
        interval = "1 hour"
        date_format = "%Y-%m-%d %H:00:00"
    elif bucket == "day":
        interval = "1 day"
        date_format = "%Y-%m-%d 00:00:00"
    else:  # week
        interval = "7 days"
        date_format = "%Y-%m-%d"  # Simplified
    
    # SQLite-specific time bucketing
    if bucket == "hour":
        time_buckets = db.query(
            func.strftime("%Y-%m-%d %H:00:00", Event.server_timestamp).label("bucket"),
            func.count(DBSession.id).label("session_count"),
            func.count(Event.id).label("event_count"),
            func.sum(func.cast(Event.alert == "DANGER", func.integer)).label("alert_count")
        ).outerjoin(
            DBSession, Event.internal_session_id == DBSession.id
        ).filter(
            Event.server_timestamp >= from_date
        ).group_by("bucket").order_by("bucket").all()
    elif bucket == "day":
        time_buckets = db.query(
            func.strftime("%Y-%m-%d", Event.server_timestamp).label("bucket"),
            func.count(DBSession.id).label("session_count"),
            func.count(Event.id).label("event_count"),
            func.sum(func.cast(Event.alert == "DANGER", func.integer)).label("alert_count")
        ).outerjoin(
            DBSession, Event.internal_session_id == DBSession.id
        ).filter(
            Event.server_timestamp >= from_date
        ).group_by("bucket").order_by("bucket").all()
    else:
        # Week bucket (simplified)
        time_buckets = db.query(
            func.strftime("%Y-%W", Event.server_timestamp).label("bucket"),
            func.count(DBSession.id).label("session_count"),
            func.count(Event.id).label("event_count"),
            func.sum(func.cast(Event.alert == "DANGER", func.integer)).label("alert_count")
        ).outerjoin(
            DBSession, Event.internal_session_id == DBSession.id
        ).filter(
            Event.server_timestamp >= from_date
        ).group_by("bucket").order_by("bucket").all()
    
    trends = []
    for bucket_str, session_count, event_count, alert_count in time_buckets:
        trends.append(DashboardTrendsResponse(
            time_bucket=bucket_str,
            session_count=session_count or 0,
            event_count=event_count or 0,
            alert_count=alert_count or 0
        ))
    
    return trends


@router.get("/api/v1/dashboard/device-health", response_model=list[DashboardDeviceHealthResponse])
async def device_health(
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Device activity and known health indicators."""
    devices = db.query(Device).all()
    
    health_data = []
    for device in devices:
        # Determine online status
        from backend.config import settings
        is_online = False
        if device.last_seen_at:
            threshold = datetime.now(timezone.utc) - timedelta(seconds=settings.device_online_threshold_seconds)
            is_online = device.last_seen_at > threshold
        
        # Count sessions and events
        total_sessions = db.query(DBSession).filter(DBSession.device_id == device.device_id).count()
        total_events = db.query(Event).filter(Event.device_id == device.device_id).count()
        
        # Get last error
        last_error = db.query(IngestionError).filter(
            IngestionError.device_id == device.device_id
        ).order_by(IngestionError.timestamp.desc()).first()
        
        health_data.append(DashboardDeviceHealthResponse(
            device_id=device.device_id,
            name=device.name,
            last_seen_at=device.last_seen_at,
            is_online=is_online,
            total_sessions=total_sessions,
            total_events=total_events,
            last_error=last_error.error_message if last_error else None
        ))
    
    return health_data


@router.get("/api/v1/dashboard/alerts", response_model=PaginatedResponse)
async def dashboard_alerts(
    page: int = Query(1, ge=1),
    page_size: int = Query(100, ge=1, le=500),
    device_id: Optional[str] = None,
    alert_type: Optional[str] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Recorded device-reported alerts with filters."""
    query = db.query(Event).filter(Event.alert.isnot(None))
    
    if device_id:
        query = query.filter(Event.device_id == device_id)
    
    if alert_type:
        query = query.filter(Event.alert == alert_type)
    
    total = query.count()
    events = query.order_by(Event.server_timestamp.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    alerts = []
    for event in events:
        alerts.append(DashboardAlertResponse(
            id=event.id,
            device_id=event.device_id,
            trainee_id=event.trainee_id,
            timestamp=event.server_timestamp,
            alert=event.alert,
            cause=event.cause or "",
            details={
                "event_name": event.event_name,
                "model_label": event.model_label,
                "leak_probability": event.leak_probability,
                "rms": event.rms,
                "gas_delta": event.gas_delta
            }
        ))
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=alerts
    )
