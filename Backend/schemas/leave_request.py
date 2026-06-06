from datetime import date, datetime
from pydantic import BaseModel
from typing import Optional


# =========================
# Create Schema
# =========================
class LeaveRequestCreate(BaseModel):
    start_date: date
    end_date: date
    leave_type: str  # 'Nghỉ phép', 'Nghỉ ốm', 'Công tác', 'Khác'
    reason: str


# =========================
# Update Schema
# =========================
class LeaveRequestUpdate(BaseModel):
    status: Optional[str] = None
    reject_reason: Optional[str] = None


# =========================
# Response Schema
# =========================
class LeaveRequestResponse(BaseModel):
    id: int
    request_code: str
    user_id: int
    user_name: Optional[str] = None
    user_email: Optional[str] = None
    user_role: Optional[str] = None
    start_date: date
    end_date: date
    leave_type: str
    reason: str
    status: str
    created_at: datetime
    approved_by: Optional[int] = None
    approved_by_name: Optional[str] = None
    approved_at: Optional[datetime] = None
    reject_reason: Optional[str] = None

    class Config:
        from_attributes = True
