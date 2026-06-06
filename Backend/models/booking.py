from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from db import Base


class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)

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

    booking_date = Column(String(50), nullable=False)
    time_slot = Column(String(100), nullable=False)
    symptoms = Column(Text, nullable=True)

    status = Column(
        String(20),
        default="pending",
        nullable=False
    )  # pending, confirmed, completed, cancelled, checked_in, in_progress

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow
    )

    # Relationships
    patient = relationship("Patient")
    doctor = relationship("Doctor")
