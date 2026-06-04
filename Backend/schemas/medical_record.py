from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional, List
from uuid import UUID
from schemas.patient import PatientOut
from schemas.service import ServiceResponse


class MedicalRecordBase(BaseModel):
    appointment_id: int
    patient_id: int
    doctor_id: UUID  # Sử dụng kiểu UUID của python
    diagnosis: str
    treatment: str
    prescription: Optional[str] = None
    notes: Optional[str] = None
    follow_up_date: Optional[date] = None


class MedicalRecordCreate(MedicalRecordBase):
    # Danh sách các ID dịch vụ nha khoa chỉ định thêm trong đợt điều trị này
    indicated_service_ids: Optional[List[int]] = []


class DoctorMin(BaseModel):
    id: UUID  # Khóa chính bác sĩ là UUID
    doctor_code: Optional[str] = None
    full_name: str
    email: str
    phone: Optional[str] = None
    specialty: Optional[str] = None

    class Config:
        from_attributes = True


class MedicalRecordOut(MedicalRecordBase):
    id: int
    created_at: datetime

    # Mở rộng quan hệ
    patient: Optional[PatientOut] = None
    doctor: Optional[DoctorMin] = None
    indicated_services: Optional[List[ServiceResponse]] = []

    class Config:
        from_attributes = True
