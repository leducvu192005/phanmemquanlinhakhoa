from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime


# =========================
# BASE
# =========================
class DoctorBase(BaseModel):
    full_name: str
    email: str
    phone: Optional[str] = None

    specialization: Optional[str] = None
    qualification: Optional[str] = None
    experience_years: Optional[int] = None

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
    full_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None

    specialization: Optional[str] = None
    qualification: Optional[str] = None
    experience_years: Optional[int] = None

    avatar: Optional[str] = None
    bio: Optional[str] = None

    status: Optional[bool] = None


# =========================
# RESPONSE
# =========================
class DoctorOut(DoctorBase):
    id: UUID
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True