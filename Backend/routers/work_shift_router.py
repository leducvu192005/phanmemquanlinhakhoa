from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from dependencies import get_db
from models.work_shift import WorkShift
from schemas.work_shift import (
    WorkShiftCreate,
    WorkShiftUpdate,
    WorkShiftResponse,
)

router = APIRouter(
    prefix="/work-shifts",
    tags=["Work Shifts"]
)


# CREATE
@router.post(
    "",
    response_model=WorkShiftResponse
)
def create_shift(
    data: WorkShiftCreate,
    db: Session = Depends(get_db)
):
    # kiểm tra giờ
    if data.end_time <= data.start_time:
        raise HTTPException(
            status_code=400,
            detail="End time must be greater than start time"
        )

    # kiểm tra mã ca trùng
    existing = (
        db.query(WorkShift)
        .filter(WorkShift.shift_code == data.shift_code)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Shift code already exists"
        )

    shift = WorkShift(**data.model_dump())

    db.add(shift)
    db.commit()
    db.refresh(shift)

    return shift


# GET ALL
@router.get(
    "",
    response_model=List[WorkShiftResponse]
)
def get_shifts(
    db: Session = Depends(get_db)
):
    return (
        db.query(WorkShift)
        .order_by(WorkShift.id.desc())
        .all()
    )


# GET BY ID
@router.get(
    "/{shift_id}",
    response_model=WorkShiftResponse
)
def get_shift(
    shift_id: int,
    db: Session = Depends(get_db)
):
    shift = (
        db.query(WorkShift)
        .filter(WorkShift.id == shift_id)
        .first()
    )

    if not shift:
        raise HTTPException(
            status_code=404,
            detail="Work shift not found"
        )

    return shift


# UPDATE
@router.put(
    "/{shift_id}",
    response_model=WorkShiftResponse
)
def update_shift(
    shift_id: int,
    data: WorkShiftUpdate,
    db: Session = Depends(get_db)
):
    shift = (
        db.query(WorkShift)
        .filter(WorkShift.id == shift_id)
        .first()
    )

    if not shift:
        raise HTTPException(
            status_code=404,
            detail="Work shift not found"
        )

    update_data = data.model_dump(
        exclude_unset=True
    )

    if (
        "start_time" in update_data
        and "end_time" in update_data
        and update_data["end_time"] <= update_data["start_time"]
    ):
        raise HTTPException(
            status_code=400,
            detail="End time must be greater than start time"
        )

    for key, value in update_data.items():
        setattr(shift, key, value)

    db.commit()
    db.refresh(shift)

    return shift


# DELETE
@router.delete("/{shift_id}")
def delete_shift(
    shift_id: int,
    db: Session = Depends(get_db)
):
    shift = (
        db.query(WorkShift)
        .filter(WorkShift.id == shift_id)
        .first()
    )

    if not shift:
        raise HTTPException(
            status_code=404,
            detail="Work shift not found"
        )

    db.delete(shift)
    db.commit()

    return {
        "message": "Work shift deleted successfully"
    }