from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, date, time
from typing import List, Optional
from uuid import UUID

from db import get_db
from models.appointment import Appointment
from models.doctor import Doctor
from models.patient import Patient
from models.service import Service
from schemas.appointment import (
    AppointmentCreate,
    AppointmentUpdate,
    AppointmentOut,
)
from dependencies import get_current_user, get_current_doctor, get_current_admin
from models.user import User

router = APIRouter(
    prefix="/appointments",
    tags=["Appointments"]
)


# ==========================================
# LẤY LỊCH HẸN HÔM NAY CỦA BÁC SĨ ĐĂNG NHẬP
# ==========================================
@router.get(
    "/doctor/today",
    response_model=List[AppointmentOut]
)
def get_doctor_today_appointments(
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db)
):
    today = date.today()
    today_start = datetime.combine(today, time.min)
    today_end = datetime.combine(today, time.max)

    appointments = db.query(Appointment).filter(
        Appointment.doctor_id == current_doctor.id,
        Appointment.appointment_time >= today_start,
        Appointment.appointment_time <= today_end
    ).order_by(Appointment.appointment_time.asc()).all()

    return appointments


# ==========================================
# LẤY TẤT CẢ LỊCH HẸN (Admin/Staff/Doctor)
# ==========================================
@router.get(
    "/",
    response_model=List[AppointmentOut]
)
def get_all_appointments(
    doctor_id: Optional[UUID] = None,
    patient_id: Optional[int] = None,
    appointment_date: Optional[date] = None,
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Appointment)

    if doctor_id:
        query = query.filter(Appointment.doctor_id == doctor_id)
    if patient_id:
        query = query.filter(Appointment.patient_id == patient_id)
    if appointment_date:
        day_start = datetime.combine(appointment_date, time.min)
        day_end = datetime.combine(appointment_date, time.max)
        query = query.filter(
            Appointment.appointment_time >= day_start,
            Appointment.appointment_time <= day_end
        )
    if status_filter:
        query = query.filter(Appointment.status == status_filter)

    return query.order_by(Appointment.appointment_time.desc()).all()


# ==========================================
# XEM CHI TIẾT LỊCH HẸN
# ==========================================
@router.get(
    "/{appointment_id}",
    response_model=AppointmentOut
)
def get_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    appointment = db.query(Appointment).filter(
        Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch hẹn"
        )
    return appointment


# ==========================================
# TẠO MỚI LỊCH HẸN
# ==========================================
@router.post(
    "/",
    response_model=AppointmentOut,
    status_code=status.HTTP_201_CREATED
)
def create_appointment(
    payload: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Kiểm tra tồn tại patient, doctor, service
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy thông tin bệnh nhân"
        )

    doctor = db.query(Doctor).filter(Doctor.id == payload.doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy thông tin bác sĩ"
        )

    service = db.query(Service).filter(Service.id == payload.service_id).first()
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy dịch vụ được chọn"
        )

    new_appointment = Appointment(
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        service_id=payload.service_id,
        appointment_time=payload.appointment_time,
        reason=payload.reason,
        status="pending", # mặc định chờ xác nhận
        created_by=current_user.id
    )

    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)

    return new_appointment


# ==========================================
# CẬP NHẬT TRẠNG THÁI LỊCH HẸN
# ==========================================
@router.patch(
    "/{appointment_id}/status",
    response_model=AppointmentOut
)
def update_appointment_status(
    appointment_id: int,
    status_update: str, # pending, confirmed, completed, cancelled, no_show
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    appointment = db.query(Appointment).filter(
        Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch hẹn"
        )

    valid_statuses = ["pending", "confirmed", "completed", "cancelled", "no_show"]
    if status_update not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Trạng thái không hợp lệ. Phải là một trong: {', '.join(valid_statuses)}"
        )

    appointment.status = status_update
    appointment.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(appointment)

    return appointment
