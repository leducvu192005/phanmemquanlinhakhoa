from sqlalchemy.orm import Session
from models.service import Service
from models.service_price_history import ServicePriceHistory
from fastapi import HTTPException
from typing import List

def update_service_price(db: Session, service_id: int, new_price: float, user_id: int):
    if new_price <= 0:
        raise HTTPException(status_code=400, detail="Price must be greater than 0")
    service = db.query(Service).filter(Service.id == service_id, Service.status == True).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    old_price = float(service.price)
    if old_price == new_price:
        raise HTTPException(status_code=400, detail="New price must be different")
    service.price = new_price
    db.commit()
    db.refresh(service)
    price_history = ServicePriceHistory(
        service_id=service_id,
        old_price=old_price,
        new_price=new_price,
        updated_by=user_id
    )
    db.add(price_history)
    db.commit()
    return service

def get_price_history(db: Session, service_id: int) -> List[ServicePriceHistory]:
    return db.query(ServicePriceHistory).filter(ServicePriceHistory.service_id == service_id).order_by(ServicePriceHistory.updated_at.desc()).all()
