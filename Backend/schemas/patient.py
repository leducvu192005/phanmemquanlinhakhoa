from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional


# =========================
# BASE SCHEMA
# =========================
class PatientBase(BaseModel):
    patient_code: str
    full_name: str
    gender: str
    date_of_birth: date

    phone: str
    email: str
    address: str

    avatar: Optional[str] = None
    blood_type: Optional[str] = None

    allergies: Optional[str] = None
    medical_history: Optional[str] = None

    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

    # 🆕 NEW FIELDS
    last_visit: Optional[datetime] = None
    notes: Optional[str] = None

    status: bool = True


# =========================
# CREATE SCHEMA
# =========================
class PatientCreate(PatientBase):
    pass


# =========================
# UPDATE SCHEMA
# =========================
class PatientUpdate(BaseModel):
    patient_code: Optional[str] = None
    full_name: Optional[str] = None
    gender: Optional[str] = None
    date_of_birth: Optional[date] = None

    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None

    avatar: Optional[str] = None
    blood_type: Optional[str] = None

    allergies: Optional[str] = None
    medical_history: Optional[str] = None

    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None

    last_visit: Optional[datetime] = None
    notes: Optional[str] = None

    status: Optional[bool] = None


# =========================
# RESPONSE SCHEMA (ADMIN API)
# =========================
class PatientOut(PatientBase):
    id: int

    class Config:
        from_attributes = True