from sqlalchemy.orm import Session
from models.service import Service
from schemas.service import ServiceCreate, ServiceUpdate
from fastapi import HTTPException, status

def get_services(db: Session, search: str = None):
    query = db.query(Service).filter(Service.status == True)
    if search:
        query = query.filter(Service.service_name.ilike(f"%{search}%"))
    return query.all()

def create_service(db: Session, service: ServiceCreate):
    if db.query(Service).filter(Service.service_name == service.service_name).first():
        raise HTTPException(status_code=400, detail="Service name already exists")
    db_service = Service(**service.dict())
    db.add(db_service)
    db.commit()
    db.refresh(db_service)
    return db_service

def update_service(db: Session, service_id: int, service: ServiceUpdate):
    db_service = db.query(Service).filter(Service.id == service_id).first()
    if not db_service:
        raise HTTPException(status_code=404, detail="Service not found")
    if service.service_name and service.service_name != db_service.service_name:
        if db.query(Service).filter(Service.service_name == service.service_name).first():
            raise HTTPException(status_code=400, detail="Service name already exists")
    for var, value in vars(service).items():
        if value is not None:
            setattr(db_service, var, value)
    db.commit()
    db.refresh(db_service)
    return db_service

def delete_service(db: Session, service_id: int):
    db_service = db.query(Service).filter(Service.id == service_id).first()
    if not db_service:
        raise HTTPException(status_code=404, detail="Service not found")
    db_service.status = False
    db.commit()
    return db_service
