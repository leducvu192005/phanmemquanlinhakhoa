from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from db import Base


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)

    patient_id = Column(Integer, ForeignKey("patients.id", ondelete="CASCADE"), nullable=False)
    doctor_id = Column(UUID(as_uuid=True), ForeignKey("doctors.id", ondelete="RESTRICT"), nullable=False)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="RESTRICT"), nullable=False)

    appointment_time = Column(DateTime, nullable=False)
    status = Column(
        String(20),
        default="pending",
        nullable=False
    ) # pending, confirmed, completed, cancelled, no_show

    reason = Column(Text, nullable=True)

    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    patient = relationship("Patient")
    doctor = relationship("Doctor")
    service = relationship("Service")
