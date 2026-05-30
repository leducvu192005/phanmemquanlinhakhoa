from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class ServiceBase(BaseModel):
    service_name: str = Field(..., min_length=1)
    description: Optional[str]
    duration_minutes: Optional[int]
    price: float = Field(..., gt=0)
    status: Optional[bool] = True
    category: str = Field(..., min_length=1)

class ServiceCreate(ServiceBase):
    pass

class ServiceUpdate(BaseModel):
    service_name: Optional[str]
    category: Optional[str]
    description: Optional[str]
    duration_minutes: Optional[int]
    price: Optional[float]
    status: Optional[bool]

class ServiceResponse(ServiceBase):
    id: int
    service_code: str
    created_at: datetime

    class Config:
        from_attributes = True
