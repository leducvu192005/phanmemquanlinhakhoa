from datetime import date
from typing import Optional
from uuid import UUID

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
from dependencies import get_current_doctor

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
# LẤY LỊCH TRỰC CHO CALENDAR BÁC SĨ
# ==========================================
@router.get("/calendar")
def get_doctor_calendar_schedules(
    db: Session = Depends(get_db),
    current_doctor: Doctor = Depends(get_current_doctor)
):
    from models.work_shift import WorkShift
    from models.booking import Booking
    from models.patient import Patient
    from models.leave_request import LeaveRequest
    from models.user import User
    from datetime import datetime, timedelta

    # 1. Query all work schedules for the current doctor
    schedules = db.query(DoctorWorkSchedule).filter(
        DoctorWorkSchedule.doctor_id == current_doctor.id
    ).all()

    calendar_items = []

    # Map work schedules
    for s in schedules:
        # Get shift details
        shift = db.query(WorkShift).filter(WorkShift.id == s.work_shift_id).first()
        if not shift:
            continue
        
        # Format timeslot string to match booking's time_slot
        start_t_str = shift.start_time.strftime("%H:%M")
        end_t_str = shift.end_time.strftime("%H:%M")
        slot_str = f"{shift.shift_name} ({start_t_str} - {end_t_str})"
        
        # Get bookings for this schedule to count and get patient names
        bookings = db.query(Booking).filter(
            Booking.doctor_id == current_doctor.id,
            Booking.booking_date == str(s.work_date),
            Booking.time_slot == slot_str,
            Booking.status != "cancelled"
        ).all()
        
        patient_names = []
        for b in bookings:
            patient = db.query(Patient).filter(Patient.id == b.patient_id).first()
            if patient:
                patient_names.append(patient.full_name)
                
        # Determine shift type (morning, afternoon, evening)
        name_lower = shift.shift_name.lower()
        if "sáng" in name_lower:
            shift_type = "morning"
        elif "chiều" in name_lower or "trưa" in name_lower:
            shift_type = "afternoon"
        elif "tối" in name_lower:
            shift_type = "evening"
        else:
            shift_type = "morning"

        calendar_items.append({
            "id": s.id,
            "date": str(s.work_date),
            "shift": shift_type,
            "shift_name": shift.shift_name,
            "start_time": start_t_str,
            "end_time": end_t_str,
            "max_patients": s.max_patients,
            "current_patients": len(bookings),
            "status": "working",
            "patients": patient_names
        })

    # 2. Query all approved leave requests for this doctor
    # Find doctor's user id from user email
    user = db.query(User).filter(User.email == current_doctor.email).first()
    if user:
        leaves = db.query(LeaveRequest).filter(
            LeaveRequest.user_id == user.id,
            LeaveRequest.status == "Approved"
        ).all()

        for l in leaves:
            # Generate calendar entries for each date in the leave range
            current_date = l.start_date
            while current_date <= l.end_date:
                calendar_items.append({
                    "id": f"leave-{l.id}-{str(current_date)}",
                    "date": str(current_date),
                    "shift": "leave",
                    "shift_name": "Nghỉ phép",
                    "start_time": "08:00",
                    "end_time": "21:00",
                    "max_patients": 0,
                    "current_patients": 0,
                    "status": "leave",
                    "patients": [],
                    "leave_type": l.leave_type,
                    "reason": l.reason
                })
                current_date += timedelta(days=1)

    return calendar_items


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
    doctor_id: Optional[UUID] = Query(None),
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
    doctor_id: UUID,
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


# ==========================================
# ĐĂNG KÝ TRỰC CA
# ==========================================
@router.put(
    "/{schedule_id}/register",
    response_model=DoctorWorkScheduleResponse
)
def register_doctor_schedule(
    schedule_id: int,
    doctor_id: UUID,
    db: Session = Depends(get_db)
):
    schedule = (
        db.query(DoctorWorkSchedule)
        .filter(DoctorWorkSchedule.id == schedule_id)
        .first()
    )

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch làm việc"
        )

    if schedule.doctor_id is not None:
        raise HTTPException(
            status_code=400,
            detail="Ca trực này đã được đăng ký bởi bác sĩ khác"
        )

    # Đăng ký bác sĩ
    schedule.doctor_id = doctor_id
    db.commit()
    db.refresh(schedule)

    return _format_schedule_response(schedule, db)


# ==========================================
# HỦY ĐĂNG KÝ TRỰC CA
# ==========================================
@router.put(
    "/{schedule_id}/unregister",
    response_model=DoctorWorkScheduleResponse
)
def unregister_doctor_schedule(
    schedule_id: int,
    db: Session = Depends(get_db)
):
    schedule = (
        db.query(DoctorWorkSchedule)
        .filter(DoctorWorkSchedule.id == schedule_id)
        .first()
    )

    if not schedule:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch làm việc"
        )

    # Ràng buộc: Không được hủy nếu đã có bệnh nhân đặt lịch
    if schedule.current_patients and schedule.current_patients > 0:
        raise HTTPException(
            status_code=400,
            detail="Không thể hủy ca trực đã có bệnh nhân đặt hẹn"
        )

    # Reset doctor_id về null
    schedule.doctor_id = None
    db.commit()
    db.refresh(schedule)

    return _format_schedule_response(schedule, db)