from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class ServiceBase(BaseModel):
    service_code: str = Field(..., min_length=1)
    service_name: str = Field(..., min_length=1)
    description: Optional[str] = None
    duration_minutes: Optional[int] = None
    price: float = Field(..., gt=0)
    status: Optional[bool] = True
    category: str = Field(..., min_length=1)

class ServiceCreate(ServiceBase):
    pass

class ServiceUpdate(BaseModel):
    service_code: Optional[str] = Field(None, min_length=1)
    service_name: Optional[str] = Field(None, min_length=1)
    category: Optional[str] = Field(None, min_length=1)
    description: Optional[str] = None
    duration_minutes: Optional[int] = None
    price: Optional[float] = Field(None, gt=0)
    status: Optional[bool] = None

class ServiceResponse(ServiceBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
