from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from uuid import UUID
from schemas.patient import PatientOut
from schemas.service import ServiceResponse


class AppointmentBase(BaseModel):
    patient_id: int
    doctor_id: UUID  # Sử dụng kiểu UUID của python
    service_id: int
    appointment_time: datetime
    reason: Optional[str] = None


class AppointmentCreate(AppointmentBase):
    pass


class AppointmentUpdate(BaseModel):
    appointment_time: Optional[datetime] = None
    service_id: Optional[int] = None
    reason: Optional[str] = None
    status: Optional[str] = None


class DoctorMin(BaseModel):
    id: UUID  # Bác sĩ có khóa chính là UUID
    doctor_code: Optional[str] = None
    full_name: str
    email: str
    phone: Optional[str] = None
    specialty: Optional[str] = None
    avatar: Optional[str] = None
    salary_coefficient: Optional[float] = 1.0

    class Config:
        from_attributes = True


class AppointmentOut(AppointmentBase):
    id: int
    status: str
    created_by: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    # Quan hệ mở rộng (nested relations)
    patient: Optional[PatientOut] = None
    service: Optional[ServiceResponse] = None
    doctor: Optional[DoctorMin] = None

    class Config:
        from_attributes = True
