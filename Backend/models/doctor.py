from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    Text,
    Date,
    DateTime
)

from sqlalchemy.sql import func
from db import Base


class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(Integer, primary_key=True, index=True)

    doctor_code = Column(
        String,
        unique=True,
        nullable=False
    )

    full_name = Column(
        String,
        nullable=False
    )

    gender = Column(String)

    date_of_birth = Column(Date)

    phone = Column(
        String,
        nullable=False
    )

    email = Column(
        String,
        unique=True,
        nullable=False
    )

    avatar = Column(Text)

    specialty = Column(String)

    qualification = Column(Text)

    experience_years = Column(Integer)

    address = Column(Text)

    bio = Column(Text)

    status = Column(
        Boolean,
        default=True
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )