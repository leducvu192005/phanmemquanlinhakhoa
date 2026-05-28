from sqlalchemy import Column, BigInteger, String, Text, Integer, DECIMAL, Boolean, DateTime
from sqlalchemy.sql import func
from .base import Base

class Service(Base):
    __tablename__ = "services"
    id = Column(BigInteger, primary_key=True, index=True)
    service_name = Column(String, unique=True, nullable=False)
    description = Column(Text)
    duration = Column(Integer)
    price = Column(DECIMAL(12,2))
    status = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
