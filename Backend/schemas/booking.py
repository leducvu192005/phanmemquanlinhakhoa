from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime
from schemas.patient import PatientOut
from schemas.appointment import DoctorMin


class BookingBase(BaseModel):
    patient_id: int
    doctor_id: UUID
    booking_date: str
    time_slot: str
    symptoms: Optional[str] = None


class BookingCreate(BookingBase):
    schedule_id: Optional[int] = None  # Nhận thêm schedule_id để tự động cập nhật ca trực


class BookingUpdate(BaseModel):
    booking_date: Optional[str] = None
    time_slot: Optional[str] = None
    symptoms: Optional[str] = None
    status: Optional[str] = None
    doctor_id: Optional[UUID] = None


class BookingOut(BookingBase):
    id: int
    status: str
    created_at: datetime
    updated_at: datetime

    patient: Optional[PatientOut] = None
    doctor: Optional[DoctorMin] = None

    class Config:
        from_attributes = True
