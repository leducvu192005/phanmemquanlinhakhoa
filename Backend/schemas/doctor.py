from pydantic import BaseModel
from typing import Optional
from datetime import date
from uuid import UUID
from datetime import datetime
# =========================
# BASE
# =========================
class DoctorBase(BaseModel):
    doctor_code: Optional[str] = None

    full_name: str
    email: str
    phone: Optional[str] = None

    gender: Optional[str] = None
    
    date_of_birth: Optional[date] = None
    specialty: Optional[str] = None   # ✅ FIX: đúng DB
    qualification: Optional[str] = None
    experience_years: Optional[int] = None

    address: Optional[str] = None
    avatar: Optional[str] = None
    bio: Optional[str] = None

    status: bool = True


# =========================
# CREATE
# =========================
class DoctorCreate(DoctorBase):
    pass


# =========================
# UPDATE
# =========================
class DoctorUpdate(BaseModel):
    doctor_code: Optional[str] = None

    full_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None

    gender: Optional[str] = None
    date_of_birth: Optional[date] = None

    specialty: Optional[str] = None   # ✅ FIX
    qualification: Optional[str] = None
    experience_years: Optional[int] = None

    address: Optional[str] = None
    avatar: Optional[str] = None
    bio: Optional[str] = None

    status: Optional[bool] = None


# =========================
# RESPONSE
# =========================
class DoctorOut(DoctorBase):
    id: UUID
    created_at: Optional[datetime] = None   
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True