from sqlalchemy import (
    Column,
    Integer,
    String,
    Text,
    Date,
    DateTime,
    ForeignKey
)
from sqlalchemy.sql import func
from db import Base


class LeaveRequest(Base):
    __tablename__ = "leave_requests"

    id = Column(Integer, primary_key=True, index=True)
    
    request_code = Column(
        String,
        unique=True,
        nullable=False,
        index=True
    )
    
    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )
    
    start_date = Column(Date, nullable=False)
    
    end_date = Column(Date, nullable=False)
    
    leave_type = Column(
        String,
        nullable=False
    )  # 'Nghỉ phép', 'Nghỉ ốm', 'Công tác', 'Khác'
    
    reason = Column(Text, nullable=False)
    
    status = Column(
        String,
        default="Pending",
        nullable=False
    )  # 'Pending', 'Approved', 'Rejected', 'Cancelled'
    
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )
    
    approved_by = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=True
    )
    
    approved_at = Column(
        DateTime(timezone=True),
        nullable=True
    )
    
    reject_reason = Column(Text, nullable=True)
