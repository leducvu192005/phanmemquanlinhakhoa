from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from db import get_db
from models.medical_record import MedicalRecord
from models.appointment import Appointment
from models.patient import Patient
from models.doctor import Doctor
from models.service import Service
from schemas.medical_record import (
    MedicalRecordCreate,
    MedicalRecordOut,
)
from dependencies import get_current_user, get_current_doctor
from models.user import User

router = APIRouter(
    prefix="/medical-records",
    tags=["Medical Records"]
)


# ==========================================
# TẠO MỚI HỒ SƠ BỆNH ÁN (Hoàn thành ca khám)
# ==========================================
@router.post(
    "/",
    response_model=MedicalRecordOut,
    status_code=status.HTTP_201_CREATED
)
def create_medical_record(
    payload: MedicalRecordCreate,
    db: Session = Depends(get_db),
    current_doctor: Doctor = Depends(get_current_doctor)
):
    # 1. Kiểm tra tồn tại ca khám (Appointment)
    appointment = db.query(Appointment).filter(
        Appointment.id == payload.appointment_id
    ).first()

    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy thông tin ca trực/lịch hẹn liên quan"
        )

    # 2. Kiểm tra bệnh nhân và bác sĩ
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy thông tin bệnh nhân"
        )

    # 3. Tạo mới bản ghi bệnh án
    new_record = MedicalRecord(
        appointment_id=payload.appointment_id,
        patient_id=payload.patient_id,
        doctor_id=current_doctor.id, # Lấy ID bác sĩ từ token hiện tại
        diagnosis=payload.diagnosis,
        treatment=payload.treatment,
        prescription=payload.prescription,
        notes=payload.notes,
        follow_up_date=payload.follow_up_date
    )

    # 4. Chỉ định dịch vụ bổ sung nếu có
    if payload.indicated_service_ids:
        services = db.query(Service).filter(
            Service.id.in_(payload.indicated_service_ids)
        ).all()
        new_record.indicated_services.extend(services)

    # 5. Cập nhật trạng thái ca khám thành "completed"
    appointment.status = "completed"
    appointment.updated_at = datetime_now = datetime_now_placeholder = Appointment.updated_at.type.python_type() if hasattr(Appointment.updated_at.type, 'python_type') else None
    
    # Cập nhật thời điểm cuối cùng ghé thăm của bệnh nhân
    patient.last_visit = datetime_now or Patient.last_visit.type.python_type() if hasattr(Patient.last_visit.type, 'python_type') else None
    if hasattr(new_record, 'created_at') and not new_record.created_at:
        from datetime import datetime
        new_record.created_at = datetime.utcnow()
        appointment.updated_at = datetime.utcnow()
        patient.last_visit = datetime.utcnow()

    db.add(new_record)
    db.commit()
    db.refresh(new_record)

    return new_record


# ==========================================
# LẤY LỊCH SỬ BỆNH ÁN CỦA BỆNH NHÂN
# ==========================================
@router.get(
    "/patient/{patient_id}",
    response_model=List[MedicalRecordOut]
)
def get_patient_medical_history(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Xác minh bệnh nhân tồn tại
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy thông tin bệnh nhân"
        )

    records = db.query(MedicalRecord).filter(
        MedicalRecord.patient_id == patient_id
    ).order_by(MedicalRecord.created_at.desc()).all()

    return records


# ==========================================
# XEM CHI TIẾT HỒ SƠ BỆNH ÁN
# ==========================================
@router.get(
    "/{record_id}",
    response_model=MedicalRecordOut
)
def get_medical_record_detail(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    record = db.query(MedicalRecord).filter(
        MedicalRecord.id == record_id
    ).first()

    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy hồ sơ bệnh án"
        )
    return record
