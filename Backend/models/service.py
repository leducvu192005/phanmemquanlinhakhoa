from sqlalchemy import (
    Column,
    Integer,
    String,
    Float,
    Boolean,
    Text,
    DateTime
)
from datetime import datetime
from db import Base
class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    service_code = Column(String(50), unique=True, nullable=False)

    service_name = Column(String(255), nullable=False)

    description = Column(Text)
    category = Column(String(255), nullable=False)
    duration_minutes = Column(Integer)

    price = Column(Float, nullable=False)

    status = Column(Boolean, default=True)

    created_at = Column(
        DateTime,
        default=datetime.utcnow
    )