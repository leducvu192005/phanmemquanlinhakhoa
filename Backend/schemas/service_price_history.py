from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class ServicePriceHistoryResponse(BaseModel):
    id: int
    service_id: int
    old_price: float
    new_price: float
    updated_by: Optional[int] = None
    updated_at: datetime

    class Config:
        from_attributes = True
