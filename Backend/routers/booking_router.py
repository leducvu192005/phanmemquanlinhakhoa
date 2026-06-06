from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from db import get_db
from models.booking import Booking
from models.doctor import Doctor
from models.patient import Patient
from models.doctor_work_schedule import DoctorWorkSchedule
from models.work_shift import WorkShift
from schemas.booking import (
    BookingCreate,
    BookingUpdate,
    BookingOut,
)
from dependencies import get_current_user
from models.user import User

router = APIRouter(
    prefix="/bookings",
    tags=["Bookings"]
)


# ==========================================
# ĐẶT LỊCH MỚI (Patient)
# ==========================================
@router.post("/", response_model=BookingOut)
def create_booking(
    payload: BookingCreate,
    db: Session = Depends(get_db)
):
    # Verify patient
    patient = db.query(Patient).filter(Patient.id == payload.patient_id).first()
    if not patient:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy thông tin bệnh nhân"
        )

    # Verify doctor
    doctor = db.query(Doctor).filter(Doctor.id == payload.doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy thông tin bác sĩ"
        )

    # Nếu có schedule_id, tự động lấy thông tin từ doctor_work_schedules
    if payload.schedule_id:
        schedule = db.query(DoctorWorkSchedule).filter(
            DoctorWorkSchedule.id == payload.schedule_id
        ).first()

        if not schedule:
            raise HTTPException(
                status_code=404,
                detail="Không tìm thấy ca trực của bác sĩ"
            )

        if schedule.doctor_id != payload.doctor_id:
            raise HTTPException(
                status_code=400,
                detail="Ca trực không thuộc về bác sĩ đã chọn"
            )

        if schedule.current_patients >= schedule.max_patients:
            raise HTTPException(
                status_code=400,
                detail="Ca trực của bác sĩ đã đầy bệnh nhân"
            )

        # Cập nhật số bệnh nhân hiện tại trong ca trực
        schedule.current_patients += 1

    # Tạo booking mới
    new_booking = Booking(
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        booking_date=payload.booking_date,
        time_slot=payload.time_slot,
        symptoms=payload.symptoms,
        status="pending"
    )

    db.add(new_booking)
    db.commit()
    db.refresh(new_booking)

    return new_booking


# ==========================================
# LẤY DANH SÁCH BOOKING CỦA TÔI (Patient)
# ==========================================
@router.get("/patient/me", response_model=List[BookingOut])
def get_my_bookings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Tìm hồ sơ bệnh nhân từ user_id
    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    if not patient:
        # Dự phòng theo email/phone
        patient = db.query(Patient).filter(
            (Patient.email == current_user.email) |
            (Patient.phone == current_user.phone)
        ).first()

    if not patient:
        return []

    bookings = db.query(Booking).filter(
        Booking.patient_id == patient.id
    ).order_by(Booking.id.desc()).all()

    return bookings


# ==========================================
# LẤY TẤT CẢ BOOKINGS (Admin/Staff)
# ==========================================
@router.get("/", response_model=List[BookingOut])
def get_all_bookings(
    doctor_id: Optional[UUID] = None,
    patient_id: Optional[int] = None,
    booking_date: Optional[str] = None,
    status_filter: Optional[str] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Booking)

    if doctor_id:
        query = query.filter(Booking.doctor_id == doctor_id)
    if patient_id:
        query = query.filter(Booking.patient_id == patient_id)
    if booking_date:
        query = query.filter(Booking.booking_date == booking_date)
    if status_filter:
        query = query.filter(Booking.status == status_filter)

    if search:
        like = f"%{search}%"
        query = query.outerjoin(Patient, Booking.patient_id == Patient.id)\
            .outerjoin(Doctor, Booking.doctor_id == Doctor.id)\
            .filter(
                (Patient.full_name.ilike(like)) |
                (Patient.patient_code.ilike(like)) |
                (Doctor.full_name.ilike(like)) |
                (Booking.symptoms.ilike(like))
            )

    return query.order_by(Booking.id.desc()).all()


# ==========================================
# THỐNG KÊ BOOKINGS (Staff/Admin)
# ==========================================
@router.get(
    "/stats/summary",
    response_model=dict
)
def get_booking_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["staff", "admin", "doctor"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập dữ liệu thống kê này"
        )

    from datetime import date
    today_str = date.today().strftime("%Y-%m-%d")

    # Thống kê tổng thể
    total_all = db.query(Booking).count()
    pending_all = db.query(Booking).filter(Booking.status == "pending").count()
    confirmed_all = db.query(Booking).filter(Booking.status == "confirmed").count()
    completed_all = db.query(Booking).filter(Booking.status == "completed").count()
    cancelled_all = db.query(Booking).filter(Booking.status == "cancelled").count()

    # Thống kê hôm nay
    total_today = db.query(Booking).filter(Booking.booking_date == today_str).count()
    pending_today = db.query(Booking).filter(Booking.booking_date == today_str, Booking.status == "pending").count()
    confirmed_today = db.query(Booking).filter(Booking.booking_date == today_str, Booking.status == "confirmed").count()
    completed_today = db.query(Booking).filter(Booking.booking_date == today_str, Booking.status == "completed").count()
    cancelled_today = db.query(Booking).filter(Booking.booking_date == today_str, Booking.status == "cancelled").count()

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
# XEM CHI TIẾT BOOKING
# ==========================================
@router.get("/{booking_id}", response_model=BookingOut)
def get_booking_detail(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch đặt khám"
        )
    return booking


# ==========================================
# CẬP NHẬT TRẠNG THÁI BOOKING (Staff/Admin)
# ==========================================
@router.put("/{booking_id}/status", response_model=BookingOut)
def update_booking_status(
    booking_id: int,
    status_update: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch đặt khám"
        )

    # Hợp lệ hóa trạng thái
    valid_statuses = ["pending", "confirmed", "completed", "cancelled", "checked_in", "in_progress"]
    if status_update not in valid_statuses:
        raise HTTPException(
            status_code=400,
            detail=f"Trạng thái không hợp lệ. Phải là một trong: {', '.join(valid_statuses)}"
        )

    booking.status = status_update
    db.commit()
    db.refresh(booking)

    return booking


# ==========================================
# HỦY ĐẶT LỊCH (Patient)
# ==========================================
@router.put("/{booking_id}/cancel", response_model=BookingOut)
def cancel_booking(
    booking_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch đặt khám"
        )

    # Đảm bảo chỉ hủy khi còn ở trạng thái pending hoặc confirmed
    if booking.status not in ["pending", "confirmed"]:
        raise HTTPException(
            status_code=400,
            detail="Chỉ có thể hủy lịch đặt ở trạng thái chờ duyệt hoặc đã xác nhận"
        )

    booking.status = "cancelled"
    db.commit()
    db.refresh(booking)

    return booking


# ==========================================
# CẬP NHẬT THÔNG TIN BOOKING (Reschedule/Reassign)
# ==========================================
@router.put("/{booking_id}", response_model=BookingOut)
def update_booking(
    booking_id: int,
    payload: BookingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy lịch đặt khám"
        )

    if payload.booking_date is not None:
        booking.booking_date = payload.booking_date
    if payload.time_slot is not None:
        booking.time_slot = payload.time_slot
    if payload.symptoms is not None:
        booking.symptoms = payload.symptoms
    if payload.status is not None:
        valid_statuses = ["pending", "confirmed", "completed", "cancelled", "checked_in", "in_progress"]
        if payload.status not in valid_statuses:
            raise HTTPException(
                status_code=400,
                detail=f"Trạng thái không hợp lệ. Phải là một trong: {', '.join(valid_statuses)}"
            )
        booking.status = payload.status
    if payload.doctor_id is not None:
        doctor = db.query(Doctor).filter(Doctor.id == payload.doctor_id).first()
        if not doctor:
            raise HTTPException(
                status_code=404,
                detail="Không tìm thấy thông tin bác sĩ"
            )
        booking.doctor_id = payload.doctor_id

    db.commit()
    db.refresh(booking)
    return booking

