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


class DoctorWorkSchedule(Base):
    __tablename__ = "doctor_work_schedules"

    id = Column(Integer, primary_key=True, index=True)

    doctor_id = Column(
    Integer,
    ForeignKey("users.id"),
    nullable=True
)

    work_shift_id = Column(
        Integer,
        ForeignKey("work_shifts.id"),
        nullable=False
    )

    work_date = Column(
        Date,
        nullable=False
    )

    max_patients = Column(
        Integer,
        default=10
    )

    current_patients = Column(
        Integer,
        default=0
    )

    status = Column(
        String(20),
        default="available"
    )

    note = Column(Text)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )