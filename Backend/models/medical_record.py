from sqlalchemy import Column, Integer, String, Text, Date, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from db import Base

# Bảng liên kết nhiều-nhiều giữa Hồ sơ bệnh án và Dịch vụ nha khoa được chỉ định
medical_record_services = Table(
    "medical_record_services",
    Base.metadata,
    Column(
        "medical_record_id",
        Integer,
        ForeignKey("medical_records.id", ondelete="CASCADE"),
        primary_key=True
    ),
    Column(
        "service_id",
        Integer,
        ForeignKey("services.id", ondelete="CASCADE"),
        primary_key=True
    )
)


class MedicalRecord(Base):
    __tablename__ = "medical_records"

    id = Column(Integer, primary_key=True, index=True)
    appointment_id = Column(
        Integer,
        ForeignKey("bookings.id", ondelete="CASCADE"),
        unique=True,
        nullable=False
    )
    patient_id = Column(
        Integer,
        ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False
    )
    doctor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("doctors.id", ondelete="RESTRICT"),
        nullable=False
    )

    diagnosis = Column(Text, nullable=False) # Chẩn đoán
    treatment = Column(Text, nullable=False) # Phương pháp điều trị
    prescription = Column(Text, nullable=True) # Đơn thuốc (dạng text linh hoạt)
    notes = Column(Text, nullable=True) # Ghi chú thêm
    follow_up_date = Column(Date, nullable=True) # Ngày tái khám

    created_at = Column(DateTime, default=datetime.utcnow)

    # Quan hệ với các bảng khác để dễ dàng query
    patient = relationship("Patient")
    doctor = relationship("Doctor")
    appointment = relationship("Booking", back_populates="medical_record")
    
    # Quan hệ nhiều-nhiều với Dịch vụ nha khoa chỉ định thêm
    indicated_services = relationship(
        "Service",
        secondary=medical_record_services,
        backref="medical_records"
    )
