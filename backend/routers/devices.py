from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import datetime, timezone, timedelta
from typing import Optional, List

from backend.database import get_db, Device, DeviceCredential, Event, Session as DBSession
from backend.auth import get_current_trainer_or_admin, get_current_admin, verify_device_key, get_password_hash
from backend.schemas import (
    DeviceRegisterRequest, DeviceResponse, DeviceStatusResponse,
    DeviceUpdateRequest, PaginatedResponse
)
from backend.config import settings

router = APIRouter()


@router.post("/api/v1/devices/register", response_model=DeviceResponse)
async def register_device(
    request: DeviceRegisterRequest,
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Register or update a device with its authentication key."""
    # Check if device already exists
    device = db.query(Device).filter(Device.device_id == request.device_id).first()
    
    if device:
        # Update existing device
        if request.name:
            device.name = request.name
        if not device.is_active:
            device.is_active = True
        db.commit()
        db.refresh(device)
    else:
        # Create new device
        device = Device(
            device_id=request.device_id,
            name=request.name or request.device_id,
            device_metadata={},
            is_active=True
        )
        db.add(device)
        db.commit()
        db.refresh(device)
    
    # Update or create device credential
    credential = db.query(DeviceCredential).filter(
        DeviceCredential.device_id == request.device_id
    ).first()
    
    key_hash = get_password_hash(request.device_key)
    
    if credential:
        credential.key_hash = key_hash
        credential.is_active = True
    else:
        credential = DeviceCredential(
            device_id=request.device_id,
            key_hash=key_hash,
            is_active=True
        )
        db.add(credential)
    
    db.commit()
    db.refresh(device)
    
    return device


@router.get("/api/v1/devices", response_model=PaginatedResponse)
async def list_devices(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Paginated device listing and filtering."""
    query = db.query(Device)
    
    if is_active is not None:
        query = query.filter(Device.is_active == is_active)
    
    if search:
        query = query.filter(
            (Device.device_id.ilike(f"%{search}%")) |
            (Device.name.ilike(f"%{search}%"))
        )
    
    total = query.count()
    devices = query.order_by(Device.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[DeviceResponse.model_validate(d) for d in devices]
    )


@router.get("/api/v1/devices/{device_id}", response_model=DeviceResponse)
async def get_device(
    device_id: str,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Device metadata and latest known activity."""
    device = db.query(Device).filter(Device.device_id == device_id).first()
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )
    return device


@router.get("/api/v1/devices/{device_id}/status", response_model=DeviceStatusResponse)
async def get_device_status(
    device_id: str,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Last-seen time, last known firmware version, recent activity and known ingestion/device errors."""
    device = db.query(Device).filter(Device.device_id == device_id).first()
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )
    
    # Determine online status
    is_online = False
    if device.last_seen_at:
        threshold = datetime.now(timezone.utc) - timedelta(seconds=settings.device_online_threshold_seconds)
        is_online = device.last_seen_at > threshold
    
    # Count recent activity (last 24 hours)
    recent_threshold = datetime.now(timezone.utc) - timedelta(hours=24)
    recent_activity_count = db.query(Event).filter(
        Event.device_id == device_id,
        Event.server_timestamp >= recent_threshold
    ).count()
    
    # Get last error (if any)
    from backend.database import IngestionError
    last_error = db.query(IngestionError).filter(
        IngestionError.device_id == device_id
    ).order_by(IngestionError.timestamp.desc()).first()
    
    return DeviceStatusResponse(
        device_id=device.device_id,
        last_seen_at=device.last_seen_at,
        firmware_version=device.firmware_version,
        is_online=is_online,
        recent_activity_count=recent_activity_count,
        last_error=last_error.error_message if last_error else None
    )


@router.patch("/api/v1/devices/{device_id}", response_model=DeviceResponse)
async def update_device(
    device_id: str,
    request: DeviceUpdateRequest,
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Update permitted device metadata using administrator authorization."""
    device = db.query(Device).filter(Device.device_id == device_id).first()
    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )
    
    if request.name is not None:
        device.name = request.name
    if request.is_active is not None:
        device.is_active = request.is_active
    if request.metadata is not None:
        device.device_metadata = request.metadata
    
    db.commit()
    db.refresh(device)
    
    return device
