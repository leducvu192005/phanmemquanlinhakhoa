from sqlalchemy import Column, Integer, String, Date, Text, ForeignKey, Boolean
from db import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)

    patient_code = Column(String, unique=True, index=True)
    full_name = Column(String)
    gender = Column(String)

    date_of_birth = Column(Date)

    phone = Column(String)
    email = Column(String)

    address = Column(Text)

    avatar = Column(String)

    blood_type = Column(String)

    allergies = Column(Text)

    medical_history = Column(Text)

    emergency_contact_name = Column(String)

    emergency_contact_phone = Column(String)

    status = Column(Boolean, default=True)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)