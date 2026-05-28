from sqlalchemy import Column, BigInteger, DECIMAL, DateTime, ForeignKey
from sqlalchemy.sql import func
from .base import Base

class ServicePriceHistory(Base):
    __tablename__ = "service_price_history"
    id = Column(BigInteger, primary_key=True, index=True)
    service_id = Column(BigInteger, ForeignKey("services.id"))
    old_price = Column(DECIMAL(12,2))
    new_price = Column(DECIMAL(12,2))
    updated_by = Column(BigInteger, ForeignKey("users.id"))
    updated_at = Column(DateTime(timezone=True), server_default=func.now())
