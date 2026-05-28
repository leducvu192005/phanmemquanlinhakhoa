from pydantic import BaseModel
from datetime import datetime

class ServicePriceHistoryResponse(BaseModel):
    id: int
    service_id: int
    old_price: float
    new_price: float
    updated_by: int
    updated_at: datetime

    class Config:
        from_attributes = True
