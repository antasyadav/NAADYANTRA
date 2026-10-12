from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from backend.database import get_db, Trainee, Session as DBSession, Assessment
from backend.auth import get_current_trainer_or_admin, get_current_admin
from backend.schemas import (
    TraineeCreateRequest, TraineeResponse, TraineeUpdateRequest,
    SessionResponse, AssessmentResponse, PaginatedResponse
)

router = APIRouter()


@router.post("/api/v1/trainees", response_model=TraineeResponse)
async def create_trainee(
    request: TraineeCreateRequest,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Create a trainee record."""
    # Check if trainee already exists
    existing = db.query(Trainee).filter(Trainee.trainee_id == request.trainee_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Trainee ID already exists"
        )
    
    trainee = Trainee(
        trainee_id=request.trainee_id,
        name=request.name,
        cohort=request.cohort,
        trainee_metadata=request.trainee_metadata or {},
        is_active=True
    )
    
    db.add(trainee)
    db.commit()
    db.refresh(trainee)
    
    return trainee


@router.get("/api/v1/trainees", response_model=PaginatedResponse)
async def list_trainees(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    cohort: Optional[str] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Search and paginate trainee records."""
    query = db.query(Trainee)
    
    if is_active is not None:
        query = query.filter(Trainee.is_active == is_active)
    
    if search:
        query = query.filter(
            (Trainee.trainee_id.ilike(f"%{search}%")) |
            (Trainee.name.ilike(f"%{search}%"))
        )
    
    if cohort:
        query = query.filter(Trainee.cohort == cohort)
    
    total = query.count()
    trainees = query.order_by(Trainee.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[TraineeResponse.model_validate(t) for t in trainees]
    )


@router.get("/api/v1/trainees/{trainee_id}", response_model=TraineeResponse)
async def get_trainee(
    trainee_id: str,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Trainee details and permitted history."""
    trainee = db.query(Trainee).filter(Trainee.trainee_id == trainee_id).first()
    if not trainee:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trainee not found"
        )
    return trainee


@router.patch("/api/v1/trainees/{trainee_id}", response_model=TraineeResponse)
async def update_trainee(
    trainee_id: str,
    request: TraineeUpdateRequest,
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Update permitted trainee metadata."""
    trainee = db.query(Trainee).filter(Trainee.trainee_id == trainee_id).first()
    if not trainee:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trainee not found"
        )
    
    if request.name is not None:
        trainee.name = request.name
    if request.cohort is not None:
        trainee.cohort = request.cohort
    if request.is_active is not None:
        trainee.is_active = request.is_active
    if request.trainee_metadata is not None:
        trainee.trainee_metadata = request.trainee_metadata
    
    db.commit()
    db.refresh(trainee)
    
    return trainee


@router.get("/api/v1/trainees/{trainee_id}/sessions", response_model=PaginatedResponse)
async def get_trainee_sessions(
    trainee_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Trainee session history."""
    trainee = db.query(Trainee).filter(Trainee.trainee_id == trainee_id).first()
    if not trainee:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trainee not found"
        )
    
    query = db.query(DBSession).filter(DBSession.trainee_id == trainee_id)
    total = query.count()
    sessions = query.order_by(DBSession.started_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[SessionResponse.model_validate(s) for s in sessions]
    )


@router.get("/api/v1/trainees/{trainee_id}/assessments", response_model=PaginatedResponse)
async def get_trainee_assessments(
    trainee_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Trainee assessment history."""
    trainee = db.query(Trainee).filter(Trainee.trainee_id == trainee_id).first()
    if not trainee:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trainee not found"
        )
    
    query = db.query(Assessment).filter(Assessment.trainee_id == trainee_id)
    total = query.count()
    assessments = query.order_by(Assessment.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[AssessmentResponse.model_validate(a) for a in assessments]
    )
