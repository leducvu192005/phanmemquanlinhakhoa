from sqlalchemy import Column, BigInteger, String, Time, Integer, Boolean, DateTime
from sqlalchemy.sql import func

from db import Base


class WorkShift(Base):
    __tablename__ = "work_shifts"

    id = Column(BigInteger, primary_key=True, index=True)
    shift_code = Column(String(20), unique=True, nullable=False)
    shift_name = Column(String(100), nullable=False)

    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    max_patients = Column(Integer, default=20)

    status = Column(Boolean, default=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )