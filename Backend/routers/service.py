from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from db import get_db
from models.service import Service
from schemas.service import (
    ServiceCreate,
    ServiceUpdate,
    ServiceResponse,
)

router = APIRouter(
    prefix="/services",
    tags=["Services"]
)


@router.get("/", response_model=list[ServiceResponse])
def get_services(
    active_only: bool = False,
    db: Session = Depends(get_db)
):
    query = db.query(Service)

    if active_only:
        query = query.filter(Service.status == True)

    return query.order_by(Service.id.desc()).all()


@router.get("/search/", response_model=list[ServiceResponse])
def search_services(
    keyword: str,
    db: Session = Depends(get_db)
):
    return (
        db.query(Service)
        .filter(Service.service_name.ilike(f"%{keyword}%"))
        .all()
    )


@router.get("/{service_id}", response_model=ServiceResponse)
def get_service(
    service_id: int,
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(
            status_code=404,
            detail="Service not found"
        )

    return service


@router.post(
    "/",
    response_model=ServiceResponse,
    status_code=status.HTTP_201_CREATED
)
def create_service(
    service: ServiceCreate,
    db: Session = Depends(get_db)
):
    existing = (
        db.query(Service)
        .filter(Service.service_name == service.service_name)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=400,
            detail="Service already exists"
        )

    new_service = Service(**service.model_dump())

    db.add(new_service)
    db.commit()
    db.refresh(new_service)

    return new_service


@router.put(
    "/{service_id}",
    response_model=ServiceResponse
)
def update_service(
    service_id: int,
    service_data: ServiceUpdate,
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(
            status_code=404,
            detail="Service not found"
        )

    update_data = service_data.model_dump(
        exclude_unset=True
    )

    for key, value in update_data.items():
        setattr(service, key, value)

    db.commit()
    db.refresh(service)

    return service


@router.delete("/{service_id}")
def delete_service(
    service_id: int,
    db: Session = Depends(get_db)
):
    service = (
        db.query(Service)
        .filter(Service.id == service_id)
        .first()
    )

    if not service:
        raise HTTPException(
            status_code=404,
            detail="Service not found"
        )

    # Soft Delete
    service.status = False

    db.commit()

    return {
        "message": "Service disabled successfully"
    }