from datetime import date, datetime
from pydantic import BaseModel
from typing import Optional
from uuid import UUID


# =========================
# Create
# =========================
class DoctorWorkScheduleCreate(BaseModel):
    doctor_id: Optional[int] = None

    work_shift_id: int

    work_date: date

    max_patients: int = 10

    status: str = "available"

    note: Optional[str] = None


# =========================
# Update
# =========================
class DoctorWorkScheduleUpdate(BaseModel):
    doctor_id: Optional[int] = None

    work_shift_id: Optional[int] = None

    work_date: Optional[date] = None

    max_patients: Optional[int] = None

    current_patients: Optional[int] = None

    status: Optional[str] = None

    note: Optional[str] = None


# =========================
# Response
# =========================
class DoctorWorkScheduleResponse(BaseModel):
    id: int

    doctor_id: Optional[UUID] = None

    work_shift_id: int

    work_date: date

    max_patients: int

    current_patients: Optional[int] = 0

    status: str

    note: Optional[str]

    created_at: datetime

    updated_at: datetime

    class Config:
        from_attributes = True


# =========================
# Detail Response
# =========================
class DoctorWorkScheduleDetail(BaseModel):
    id: int

    doctor_id: Optional[UUID] = None

    work_shift_id: int

    work_date: date

    shift_name: str

    start_time: str

    end_time: str

    max_patients: int

    current_patients: Optional[int] = 0

    status: str

    note: Optional[str]

    class Config:
        from_attributes = True
