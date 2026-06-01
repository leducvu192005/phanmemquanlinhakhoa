from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from db import SessionLocal
from models.doctor_work_schedule import DoctorWorkSchedule
from models.doctor import Doctor
from schemas.doctor_work_schedule import (
    DoctorWorkScheduleCreate,
    DoctorWorkScheduleUpdate,
    DoctorWorkScheduleResponse
)

router = APIRouter(
    prefix="/doctor-work-schedules",
    tags=["Doctor Work Schedules"]
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _format_schedule_response(schedule: DoctorWorkSchedule, db: Session) -> DoctorWorkScheduleResponse:
    """
    Helper function để format DoctorWorkSchedule thành response
    với doctor_name, doctor_code từ Doctor table
    """
    doctor_name = None
    doctor_code = None

    if schedule.doctor_id is not None:
        doctor = db.query(Doctor).filter(
            Doctor.id == schedule.doctor_id
        ).first()

        if doctor:
            doctor_name = doctor.full_name
            doctor_code = doctor.doctor_code

    return DoctorWorkScheduleResponse(
        id=schedule.id,
        doctor_id=schedule.doctor_id,
        doctor_name=doctor_name,
        doctor_code=doctor_code,
        work_shift_id=schedule.work_shift_id,
        work_date=schedule.work_date,
        max_patients=schedule.max_patients,
        current_patients=schedule.current_patients,
        status=schedule.status,
        note=schedule.note,
        created_at=schedule.created_at,
        updated_at=schedule.updated_at
    )


# ==========================================
# TẠO LỊCH LÀM VIỆC
# ==========================================
@router.post(
    "/",
    response_model=DoctorWorkScheduleResponse
)
def create_schedule(
    schedule: DoctorWorkScheduleCreate,
    db: Session = Depends(get_db)
):

    # Chỉ check trùng lặp khi doctor_id không null
    if schedule.doctor_id is not None:
        existing = (
            db.query(DoctorWorkSchedule)
            .filter(
                DoctorWorkSchedule.doctor_id == schedule.doctor_id,
                DoctorWorkSchedule.work_shift_id == schedule.work_shift_id,
                DoctorWorkSchedule.work_date == schedule.work_date
            )
            .first()
        )

        if existing:
            raise HTTPException(
                status_code=400,
                detail="Lịch làm việc đã tồn tại"
            )

    new_schedule = DoctorWorkSchedule(
        doctor_id=schedule.doctor_id,
        work_shift_id=schedule.work_shift_id,
        work_date=schedule.work_date,
        max_patients=schedule.max_patients,
        status=schedule.status,
        note=schedule.note
    )

    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)

    return _format_schedule_response(new_schedule, db)


# ==========================================
# LẤY TẤT CẢ LỊCH
# ==========================================
@router.get(
    "/",
    response_model=list[DoctorWorkScheduleResponse]
)
def get_all_schedules(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):

    schedules = (
        db.query(DoctorWorkSchedule)
        .offset(skip)
        .limit(limit)
        .all()
    )

    return [_format_schedule_response(schedule, db) for schedule in schedules]


# ==========================================
# XEM CHI TIẾT
# ==========================================
@router.get(
    "/{schedule_id}",
    response_model=DoctorWorkScheduleResponse
)
def get_schedule_detail(
    schedule_id: int,
    db: Session = Depends(get_db)
):

    schedule = (
        db.query(DoctorWorkSchedule)
        .filter(
            DoctorWorkSchedule.id == schedule_id
        )
        .first()
    )

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch làm việc"
        )

    return _format_schedule_response(schedule, db)


# ==========================================
# TÌM KIẾM
# ==========================================
@router.get("/search/")
def search_schedules(
    doctor_id: Optional[int] = Query(None),
    work_shift_id: Optional[int] = Query(None),
    work_date: Optional[date] = Query(None),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):

    query = db.query(DoctorWorkSchedule)

    if doctor_id:
        query = query.filter(
            DoctorWorkSchedule.doctor_id == doctor_id
        )

    if work_shift_id:
        query = query.filter(
            DoctorWorkSchedule.work_shift_id == work_shift_id
        )

    if work_date:
        query = query.filter(
            DoctorWorkSchedule.work_date == work_date
        )

    if status:
        query = query.filter(
            DoctorWorkSchedule.status == status
        )

    schedules = query.all()
    return [_format_schedule_response(schedule, db) for schedule in schedules]


# ==========================================
# CẬP NHẬT
# ==========================================
@router.put(
    "/{schedule_id}",
    response_model=DoctorWorkScheduleResponse
)
def update_schedule(
    schedule_id: int,
    schedule_update: DoctorWorkScheduleUpdate,
    db: Session = Depends(get_db)
):

    schedule = (
        db.query(DoctorWorkSchedule)
        .filter(
            DoctorWorkSchedule.id == schedule_id
        )
        .first()
    )

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch làm việc"
        )

    update_data = schedule_update.model_dump(
        exclude_unset=True
    )

    for key, value in update_data.items():
        setattr(schedule, key, value)

    db.commit()
    db.refresh(schedule)

    return _format_schedule_response(schedule, db)


# ==========================================
# XÓA
# ==========================================
@router.delete("/{schedule_id}")
def delete_schedule(
    schedule_id: int,
    db: Session = Depends(get_db)
):

    schedule = (
        db.query(DoctorWorkSchedule)
        .filter(
            DoctorWorkSchedule.id == schedule_id
        )
        .first()
    )

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch làm việc"
        )

    db.delete(schedule)
    db.commit()

    return {
        "message": "Xóa lịch làm việc thành công"
    }


# ==========================================
# LỊCH CỦA BÁC SĨ
# ==========================================
@router.get("/doctor/{doctor_id}")
def get_doctor_schedules(
    doctor_id: int,
    db: Session = Depends(get_db)
):

    schedules = (
        db.query(DoctorWorkSchedule)
        .filter(
            DoctorWorkSchedule.doctor_id == doctor_id
        )
        .all()
    )

    return [_format_schedule_response(schedule, db) for schedule in schedules]


# ==========================================
# CA CÒN TRỐNG
# ==========================================
@router.get("/status/open/list")
def get_open_schedules(
    db: Session = Depends(get_db)
):

    schedules = (
        db.query(DoctorWorkSchedule)
        .filter(
            DoctorWorkSchedule.status == "available"
        )
        .all()
    )

    return [_format_schedule_response(schedule, db) for schedule in schedules]