from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from db import get_db
from models.patient import Patient
from models.user import User
from schemas.patient import PatientOut
from dependencies import get_current_user

router = APIRouter(
    tags=["Patients"]
)

def get_current_patient_record(current_user: User, db: Session) -> Optional[Patient]:
    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    if not patient:
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
    if not patient:
        patient = db.query(Patient).filter(Patient.phone == current_user.phone).first()
    return patient

@router.get("/me", response_model=PatientOut)
def get_my_patient_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    patient = get_current_patient_record(current_user, db)
    if not patient:
        # Tự động tạo hồ sơ bệnh nhân từ tài khoản user nếu chưa có
        import random
        patient_code = f"BN{random.randint(1000, 9999)}"
        patient = Patient(
            patient_code=patient_code,
            full_name=current_user.username,
            phone=current_user.phone,
            email=current_user.email,
            user_id=current_user.id,
            status=True
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)
    return patient

@router.get("/", response_model=list[PatientOut])
def get_patients(db: Session = Depends(get_db)):
    return db.query(Patient).all()