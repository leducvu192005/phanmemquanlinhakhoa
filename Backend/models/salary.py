from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Date
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from db import Base


class SalaryConfig(Base):
    __tablename__ = "salary_configs"

    id = Column(Integer, primary_key=True, index=True)
    base_salary_per_hour = Column(Float, nullable=False, default=200000.0)
    effective_date = Column(Date, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class SalaryShiftCoefficient(Base):
    __tablename__ = "salary_shift_coefficients"

    id = Column(Integer, primary_key=True, index=True)
    shift_name = Column(String(100), unique=True, nullable=False) # e.g. "Ca sáng", "Ca chiều", "Ca tối", "Thứ 7", "Chủ nhật"
    coefficient = Column(Float, nullable=False, default=1.0)
    created_at = Column(DateTime, default=datetime.utcnow)


class SalaryComplexityCoefficient(Base):
    __tablename__ = "salary_complexity_coefficients"

    id = Column(Integer, primary_key=True, index=True)
    complexity_level = Column(String(100), unique=True, nullable=False) # e.g. "Thông thường", "Khó", "Khó vừa", "Rất khó"
    coefficient = Column(Float, nullable=False, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)


class SalarySlip(Base):
    __tablename__ = "salary_slips"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("doctors.id", ondelete="CASCADE"),
        nullable=False
    )
    month = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)

    base_rate = Column(Float, nullable=False) # Đơn giá giờ tại thời điểm lập phiếu
    doctor_coefficient = Column(Float, nullable=False) # Hệ số bác sĩ tại thời điểm lập phiếu

    total_shifts = Column(Integer, nullable=False, default=0) # Tổng số ca làm việc
    total_hours = Column(Float, nullable=False, default=0.0) # Tổng số giờ làm việc thực tế
    total_complexity_coef = Column(Float, nullable=False, default=0.0) # Tổng hệ số bệnh nhân
    total_salary = Column(Float, nullable=False, default=0.0) # Tổng tiền lương cuối cùng

    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )

    # Relationships
    doctor = relationship("Doctor")
    creator = relationship("User")
