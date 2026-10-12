from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
import uuid

from backend.database import get_db, AssessmentRubric, Assessment, TrainerReview, Session as DBSession, Event
from backend.auth import get_current_trainer_or_admin, get_current_admin
from backend.schemas import (
    AssessmentRubricCreateRequest, AssessmentRubricResponse,
    AssessmentCreateRequest, AssessmentResponse,
    TrainerReviewRequest, TrainerReviewResponse, PaginatedResponse
)

router = APIRouter()


@router.get("/api/v1/assessment-rubrics", response_model=PaginatedResponse)
async def list_rubrics(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    is_active: Optional[bool] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """List rubric versions."""
    query = db.query(AssessmentRubric)
    
    if is_active is not None:
        query = query.filter(AssessmentRubric.is_active == is_active)
    
    total = query.count()
    rubrics = query.order_by(AssessmentRubric.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[AssessmentRubricResponse.model_validate(r) for r in rubrics]
    )


@router.post("/api/v1/assessment-rubrics", response_model=AssessmentRubricResponse)
async def create_rubric(
    request: AssessmentRubricCreateRequest,
    current_user = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    """Authorized creation of a draft rubric version."""
    # Check if rubric_id already exists
    existing = db.query(AssessmentRubric).filter(AssessmentRubric.rubric_id == request.rubric_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Rubric ID already exists"
        )
    
    rubric = AssessmentRubric(
        rubric_id=request.rubric_id,
        version=request.version,
        name=request.name,
        description=request.description,
        rules=request.rules,
        created_by=current_user.username,
        is_active=True
    )
    
    db.add(rubric)
    db.commit()
    db.refresh(rubric)
    
    return rubric


@router.get("/api/v1/assessment-rubrics/{rubric_id}", response_model=AssessmentRubricResponse)
async def get_rubric(
    rubric_id: str,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Retrieve rubric definition and version."""
    rubric = db.query(AssessmentRubric).filter(AssessmentRubric.rubric_id == rubric_id).first()
    if not rubric:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rubric not found"
        )
    return rubric


@router.post("/api/v1/assessments", response_model=AssessmentResponse)
async def create_assessment(
    request: AssessmentCreateRequest,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Create a session-linked assessment with trainee, rubric version, evidence event IDs and scoring explanation."""
    # Verify session exists
    session = db.query(DBSession).filter(DBSession.id == request.session_id).first()
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found"
        )
    
    # Verify rubric exists
    rubric = db.query(AssessmentRubric).filter(AssessmentRubric.rubric_id == request.rubric_id).first()
    if not rubric:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rubric not found"
        )
    
    # Verify evidence events exist and belong to the session
    evidence_events = db.query(Event).filter(
        Event.id.in_(request.evidence_event_ids),
        Event.internal_session_id == request.session_id
    ).all()
    
    if len(evidence_events) != len(request.evidence_event_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Some evidence events not found or do not belong to this session"
        )
    
    # Check if assessment_id already exists
    existing = db.query(Assessment).filter(Assessment.assessment_id == request.assessment_id).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Assessment ID already exists"
        )
    
    # If insufficient evidence, mark as not assessable
    if not request.evidence_event_ids:
        outcome = "not_assessable"
        scoring_explanation = "No evidence events provided - cannot assess"
    else:
        outcome = "needs_improvement"  # Default outcome
        scoring_explanation = request.scoring_explanation or "Assessment created pending review"
    
    assessment = Assessment(
        assessment_id=request.assessment_id,
        session_id=request.session_id,
        trainee_id=session.trainee_id,
        rubric_id=request.rubric_id,
        rubric_version=request.rubric_version,
        evidence_event_ids=request.evidence_event_ids,
        score=None,  # To be calculated by rubric or manual review
        max_score=None,
        outcome=outcome,
        scoring_explanation=scoring_explanation,
        created_by=current_user.username
    )
    
    db.add(assessment)
    db.commit()
    db.refresh(assessment)
    
    return assessment


@router.get("/api/v1/assessments", response_model=PaginatedResponse)
async def list_assessments(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    trainee_id: Optional[str] = None,
    rubric_id: Optional[str] = None,
    outcome: Optional[str] = None,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Filter and paginate assessments."""
    query = db.query(Assessment)
    
    if trainee_id:
        query = query.filter(Assessment.trainee_id == trainee_id)
    
    if rubric_id:
        query = query.filter(Assessment.rubric_id == rubric_id)
    
    if outcome:
        query = query.filter(Assessment.outcome == outcome)
    
    total = query.count()
    assessments = query.order_by(Assessment.created_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[AssessmentResponse.model_validate(a) for a in assessments]
    )


@router.get("/api/v1/assessments/{assessment_id}", response_model=AssessmentResponse)
async def get_assessment(
    assessment_id: str,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Return assessment, evidence, score breakdown and trainer review."""
    assessment = db.query(Assessment).filter(Assessment.assessment_id == assessment_id).first()
    if not assessment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assessment not found"
        )
    return assessment


@router.post("/api/v1/assessments/{assessment_id}/review", response_model=TrainerReviewResponse)
async def create_review(
    assessment_id: str,
    request: TrainerReviewRequest,
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Trainer review, comments and permitted overrides."""
    assessment = db.query(Assessment).filter(Assessment.assessment_id == assessment_id).first()
    if not assessment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assessment not found"
        )
    
    review = TrainerReview(
        assessment_id=assessment_id,
        reviewer=current_user.username,
        comments=request.comments,
        override_score=request.override_score,
        override_outcome=request.override_outcome
    )
    
    db.add(review)
    
    # Apply overrides if provided
    if request.override_score is not None:
        assessment.score = request.override_score
    if request.override_outcome is not None:
        assessment.outcome = request.override_outcome
    
    db.commit()
    db.refresh(review)
    
    return review


@router.get("/api/v1/assessments/{assessment_id}/audit", response_model=PaginatedResponse)
async def get_assessment_audit(
    assessment_id: str,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user = Depends(get_current_trainer_or_admin),
    db: Session = Depends(get_db)
):
    """Retrieve authorized audit history."""
    assessment = db.query(Assessment).filter(Assessment.assessment_id == assessment_id).first()
    if not assessment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Assessment not found"
        )
    
    query = db.query(TrainerReview).filter(TrainerReview.assessment_id == assessment_id)
    total = query.count()
    reviews = query.order_by(TrainerReview.reviewed_at.desc()).offset((page - 1) * page_size).limit(page_size).all()
    
    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[TrainerReviewResponse.model_validate(r) for r in reviews]
    )
