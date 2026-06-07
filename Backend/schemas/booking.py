from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import datetime
from schemas.patient import PatientOut
from schemas.appointment import DoctorMin
from schemas.service import ServiceResponse


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


class BookingPay(BaseModel):
    payment_method: str
    discount_amount: float
    total_amount: float


class BookingOut(BookingBase):
    id: int
    status: str
    payment_status: str
    payment_method: Optional[str] = None
    payment_time: Optional[datetime] = None
    discount_amount: float
    total_amount: float
    created_at: datetime
    updated_at: datetime

    patient: Optional[PatientOut] = None
    doctor: Optional[DoctorMin] = None
    services: List[ServiceResponse] = []

    class Config:
        from_attributes = True
