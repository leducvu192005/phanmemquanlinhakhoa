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
    search: Optional[str] = None,
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
    if search:
        like = f"%{search}%"
        query = query.outerjoin(Patient, Appointment.patient_id == Patient.id).outerjoin(Doctor, Appointment.doctor_id == Doctor.id).filter(
            (Patient.full_name.ilike(like)) |
            (Patient.patient_code.ilike(like)) |
            (Doctor.full_name.ilike(like)) |
            (Doctor.doctor_code.ilike(like)) |
            (Appointment.reason.ilike(like))
        )

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
    status_update: str, # pending, confirmed, checked_in, in_progress, completed, cancelled, no_show
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

    valid_statuses = ["pending", "confirmed", "checked_in", "in_progress", "completed", "cancelled", "no_show"]
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


# ==========================================
# HELPER: LẤY BỆNH NHÂN CỦA USER ĐĂNG NHẬP
# ==========================================
def get_current_patient(current_user: User, db: Session) -> Optional[Patient]:
    # Thử tìm theo user_id dạng string (UUID) hoặc integer
    patient = db.query(Patient).filter(Patient.user_id == str(current_user.id)).first()
    if not patient:
        try:
            # Dự phòng nếu user_id là integer
            patient = db.query(Patient).filter(Patient.user_id == int(current_user.id)).first()
        except Exception:
            pass
    if not patient:
        # Dự phòng theo email
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
    if not patient:
        # Dự phòng theo số điện thoại
        patient = db.query(Patient).filter(Patient.phone == current_user.phone).first()
    return patient


# ==========================================
# LẤY LỊCH HẸN CỦA CHÍNH BỆNH NHÂN (Me)
# ==========================================
@router.get(
    "/patient/me",
    response_model=List[AppointmentOut]
)
def get_my_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    patient = get_current_patient(current_user, db)
    if not patient:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy hồ sơ bệnh nhân tương ứng với tài khoản đăng nhập"
        )
    
    appointments = db.query(Appointment).filter(
        Appointment.patient_id == patient.id
    ).order_by(Appointment.appointment_time.desc()).all()
    
    return appointments


# ==========================================
# HỦY LỊCH HẸN (Dành cho Patient/Staff/Admin)
# ==========================================
@router.put(
    "/{appointment_id}/cancel",
    response_model=AppointmentOut
)
def cancel_appointment(
    appointment_id: int,
    reason: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch hẹn"
        )

    # Kiểm tra quyền hạn
    if current_user.role == "user" or current_user.role == "patient":
        patient = get_current_patient(current_user, db)
        if not patient or appointment.patient_id != patient.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền hủy lịch hẹn này"
            )
        if appointment.status not in ["pending", "confirmed"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bệnh nhân chỉ được phép hủy lịch khám ở trạng thái Chờ xác nhận hoặc Đã xác nhận"
            )
    elif current_user.role not in ["staff", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền thực hiện hành động này"
        )

    appointment.status = "cancelled"
    if reason:
        appointment.reason = reason
    appointment.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(appointment)

    return appointment


# ==========================================
# ĐẶT LẠI LỊCH HẸN TỪ THÔNG TIN CŨ (Patient)
# ==========================================
@router.post(
    "/{appointment_id}/rebook",
    response_model=AppointmentOut,
    status_code=status.HTTP_201_CREATED
)
def rebook_appointment(
    appointment_id: int,
    appointment_time: datetime,
    reason: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    old_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not old_appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch hẹn cũ"
        )

    # Kiểm tra quyền hạn bệnh nhân
    if current_user.role == "user" or current_user.role == "patient":
        patient = get_current_patient(current_user, db)
        if not patient or old_appointment.patient_id != patient.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Bạn không có quyền đặt lại lịch hẹn từ hồ sơ này"
            )

    if appointment_time < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Thời gian hẹn mới không thể ở trong quá khứ"
        )

    new_appointment = Appointment(
        patient_id=old_appointment.patient_id,
        doctor_id=old_appointment.doctor_id,
        service_id=old_appointment.service_id,
        appointment_time=appointment_time,
        reason=reason or old_appointment.reason,
        status="pending",
        created_by=current_user.id
    )

    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)

    return new_appointment


# ==========================================
# THỐNG KÊ LỊCH HẸN (Staff/Admin)
# ==========================================
@router.get(
    "/stats/summary",
    response_model=dict
)
def get_appointment_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["staff", "admin", "doctor"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập dữ liệu thống kê này"
        )

    today = date.today()
    today_start = datetime.combine(today, time.min)
    today_end = datetime.combine(today, time.max)

    # Thống kê tổng thể
    total_all = db.query(Appointment).count()
    pending_all = db.query(Appointment).filter(Appointment.status == "pending").count()
    confirmed_all = db.query(Appointment).filter(Appointment.status == "confirmed").count()
    completed_all = db.query(Appointment).filter(Appointment.status == "completed").count()
    cancelled_all = db.query(Appointment).filter(Appointment.status == "cancelled").count()

    # Thống kê hôm nay
    total_today = db.query(Appointment).filter(Appointment.appointment_time >= today_start, Appointment.appointment_time <= today_end).count()
    pending_today = db.query(Appointment).filter(Appointment.appointment_time >= today_start, Appointment.appointment_time <= today_end, Appointment.status == "pending").count()
    confirmed_today = db.query(Appointment).filter(Appointment.appointment_time >= today_start, Appointment.appointment_time <= today_end, Appointment.status == "confirmed").count()
    completed_today = db.query(Appointment).filter(Appointment.appointment_time >= today_start, Appointment.appointment_time <= today_end, Appointment.status == "completed").count()
    cancelled_today = db.query(Appointment).filter(Appointment.appointment_time >= today_start, Appointment.appointment_time <= today_end, Appointment.status == "cancelled").count()

    return {
        "all": {
            "total": total_all,
            "pending": pending_all,
            "confirmed": confirmed_all,
            "completed": completed_all,
            "cancelled": cancelled_all
        },
        "today": {
            "total": total_today,
            "pending": pending_today,
            "confirmed": confirmed_today,
            "completed": completed_today,
            "cancelled": cancelled_today
        }
    }


# ==========================================
# ĐỔI LỊCH HẸN (Staff/Admin)
# ==========================================
@router.patch(
    "/{appointment_id}/reschedule",
    response_model=AppointmentOut
)
def reschedule_appointment(
    appointment_id: int,
    new_time: datetime,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["staff", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Chỉ nhân viên mới được đổi lịch khám"
        )

    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch hẹn"
        )

    if new_time < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Thời gian đổi lịch khám không thể ở trong quá khứ"
        )

    appointment.appointment_time = new_time
    appointment.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(appointment)

    return appointment


# ==========================================
# CHUYỂN BÁC SĨ (Staff/Admin)
# ==========================================
@router.patch(
    "/{appointment_id}/reassign",
    response_model=AppointmentOut
)
def reassign_doctor(
    appointment_id: int,
    new_doctor_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["staff", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Chỉ nhân viên mới được chuyển bác sĩ"
        )

    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy lịch hẹn"
        )

    doctor = db.query(Doctor).filter(Doctor.id == new_doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bác sĩ chỉ định không tồn tại"
        )

    appointment.doctor_id = new_doctor_id
    appointment.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(appointment)

    return appointment


# ==========================================
# LẤY HÀNG CHỜ HÔM NAY (Staff/Admin)
# ==========================================
@router.get(
    "/queue/today",
    response_model=List[AppointmentOut]
)
def get_today_queue(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["staff", "admin", "doctor"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền xem hàng chờ"
        )

    today = date.today()
    today_start = datetime.combine(today, time.min)
    today_end = datetime.combine(today, time.max)

    # Lấy các bệnh nhân đã check_in hoặc in_progress ngày hôm nay
    queue = db.query(Appointment).filter(
        Appointment.appointment_time >= today_start,
        Appointment.appointment_time <= today_end,
        Appointment.status.in_(["checked_in", "in_progress"])
    ).order_by(Appointment.updated_at.asc()).all()

    return queue
