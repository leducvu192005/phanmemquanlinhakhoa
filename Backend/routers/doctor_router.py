from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db import SessionLocal
from models.doctor import Doctor
from uuid import UUID
from schemas.doctor import (
    DoctorCreate,
    DoctorUpdate,
    DoctorOut,
)

router = APIRouter(
    prefix="/doctors",
    tags=["Doctors"],
)


# =========================
# DATABASE
# =========================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# =========================
# GET ALL DOCTORS
# =========================
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


# =========================
# GET DOCTOR DETAIL
# =========================
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
            detail="Doctor not found",
        )

    return doctor


# =========================
# CREATE DOCTOR
# =========================
@router.post("/", response_model=DoctorOut)
def create_doctor(
    body: DoctorCreate,
    db: Session = Depends(get_db),
):
    doctor = Doctor(**body.dict())

    db.add(doctor)
    db.commit()
    db.refresh(doctor)

    return doctor


# =========================
# UPDATE DOCTOR
# =========================
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
            detail="Doctor not found",
        )

    update_data = body.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(doctor, key, value)

    db.commit()
    db.refresh(doctor)

    return doctor


# =========================
# DELETE DOCTOR
# =========================
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
            detail="Doctor not found",
        )

    db.delete(doctor)
    db.commit()

    return {
        "message": "Doctor deleted successfully"
    }