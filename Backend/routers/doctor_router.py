from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from uuid import UUID
import os
import uuid
import shutil

from db import SessionLocal
from models.doctor import Doctor
from schemas.doctor import (
    DoctorCreate,
    DoctorUpdate,
    DoctorOut,
)
from dependencies import get_db, get_current_doctor

router = APIRouter(
    prefix="/doctors",
    tags=["Doctors"],
)


# ==========================================
# LẤY THÔNG TIN PROFILE CỦA BÁC SĨ ĐĂNG NHẬP
# ==========================================
@router.get("/me", response_model=DoctorOut)
def get_doctor_profile(
    current_doctor: Doctor = Depends(get_current_doctor),
):
    return current_doctor


# ==========================================
# CẬP NHẬT PROFILE CỦA BÁC SĨ ĐĂNG NHẬP
# ==========================================
@router.put("/me", response_model=DoctorOut)
def update_doctor_profile(
    body: DoctorUpdate,
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db),
):
    update_data = body.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(current_doctor, key, value)

    db.commit()
    db.refresh(current_doctor)

    return current_doctor


# ==========================================
# TẢI ẢNH ĐẠI DIỆN BÁC SĨ LÊN
# ==========================================
@router.post("/me/avatar")
async def upload_doctor_avatar(
    file: UploadFile = File(...),
    current_doctor: Doctor = Depends(get_current_doctor),
    db: Session = Depends(get_db),
):
    # Tạo thư mục nếu chưa tồn tại
    upload_dir = "static/avatars"
    os.makedirs(upload_dir, exist_ok=True)

    # Lấy định dạng file
    ext = os.path.splitext(file.filename)[1]
    if ext.lower() not in [".jpg", ".jpeg", ".png", ".gif", ".webp"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Định dạng tệp ảnh không hợp lệ. Chỉ chấp nhận .jpg, .jpeg, .png, .gif, .webp"
        )

    # Đặt tên file ngẫu nhiên để tránh trùng
    filename = f"{uuid.uuid4()}{ext}"
    filepath = os.path.join(upload_dir, filename)

    # Lưu file
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Lưu đường dẫn tương đối vào DB
    relative_url = f"/static/avatars/{filename}"
    current_doctor.avatar = relative_url
    
    db.commit()
    db.refresh(current_doctor)

    return {
        "avatar_url": relative_url,
        "message": "Tải ảnh đại diện lên thành công!"
    }


# ==========================================
# LẤY TẤT CẢ BÁC SĨ (Admin/Staff/Patient xem)
# ==========================================
@router.get("/", response_model=list[DoctorOut])
def get_doctors(
    q: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Doctor)

    if q:
        query = query.filter(
            Doctor.full_name.ilike(f"%{q}%")
        )

    return query.order_by(Doctor.id.desc()).all()


# ==========================================
# LẤY CHI TIẾT BÁC SĨ THEO ID (UUID)
# ==========================================
@router.get("/{doctor_id}", response_model=DoctorOut)
def get_doctor(
    doctor_id: UUID,
    db: Session = Depends(get_db),
):
    doctor = (
        db.query(Doctor)
        .filter(Doctor.id == doctor_id)
        .first()
    )

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy bác sĩ",
        )

    return doctor


# ==========================================
# TẠO MỚI BÁC SĨ (Admin API)
# ==========================================
@router.post("/", response_model=DoctorOut)
def create_doctor(
    body: DoctorCreate,
    db: Session = Depends(get_db),
):
    doctor = Doctor(**body.dict())
    if not doctor.id:
        doctor.id = uuid.uuid4()

    db.add(doctor)
    db.commit()
    db.refresh(doctor)

    return doctor


# ==========================================
# CẬP NHẬT BÁC SĨ THEO ID (UUID)
# ==========================================
@router.put("/{doctor_id}", response_model=DoctorOut)
def update_doctor(
    doctor_id: UUID,
    body: DoctorUpdate,
    db: Session = Depends(get_db),
):
    doctor = (
        db.query(Doctor)
        .filter(Doctor.id == doctor_id)
        .first()
    )

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy bác sĩ",
        )

    update_data = body.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(doctor, key, value)

    db.commit()
    db.refresh(doctor)

    return doctor


# ==========================================
# XÓA BÁC SĨ THEO ID (UUID)
# ==========================================
@router.delete("/{doctor_id}")
def delete_doctor(
    doctor_id: UUID,
    db: Session = Depends(get_db),
):
    doctor = (
        db.query(Doctor)
        .filter(Doctor.id == doctor_id)
        .first()
    )

    if not doctor:
        raise HTTPException(
            status_code=404,
            detail="Không tìm thấy bác sĩ",
        )

    db.delete(doctor)
    db.commit()

    return {
        "message": "Đã xóa bác sĩ thành công"
    }