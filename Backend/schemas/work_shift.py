from pydantic import BaseModel
from datetime import time
from typing import Optional


class WorkShiftCreate(BaseModel):
    shift_code: str
    shift_name: str
    start_time: time
    end_time: time
    max_patients: int = 20
    status: bool = True
class WorkShiftUpdate(BaseModel):
    shift_code: Optional[str] = None
    shift_name: Optional[str] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    max_patients: Optional[int] = None
    status: Optional[bool] = None
from datetime import datetime


class WorkShiftResponse(BaseModel):
    id: int
    shift_code: str
    shift_name: str

    start_time: time
    end_time: time

    max_patients: int
    status: bool

    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True