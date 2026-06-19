from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from db import get_db
from models.service import Service
from schemas.service import (
    ServiceCreate,
    ServiceUpdate,
    ServiceResponse,
)
from schemas.service_price_history import ServicePriceHistoryResponse

router = APIRouter(
    prefix="/services",
    tags=["Services"]
)


@router.get("/", response_model=list[ServiceResponse])
def get_services(
    active_only: bool = True,
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
        .filter(
            (Service.service_name.ilike(f"%{keyword}%")) |
            (Service.service_code.ilike(f"%{keyword}%"))
        )
        .filter(Service.status == True)
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
    existing_name = (
        db.query(Service)
        .filter(Service.service_name == service.service_name)
        .first()
    )

    if existing_name:
        raise HTTPException(
            status_code=400,
            detail="Service name already exists"
        )

    existing_code = (
        db.query(Service)
        .filter(Service.service_code == service.service_code)
        .first()
    )

    if existing_code:
        raise HTTPException(
            status_code=400,
            detail="Service code already exists"
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

    try:
        # Thử xóa cứng trước (nếu không có ràng buộc khóa ngoại)
        db.delete(service)
        db.commit()
        return {
            "message": "Service deleted successfully"
        }
    except Exception:
        # Fallback sang xóa mềm nếu có ràng buộc khóa ngoại (ví dụ: đã có lịch hẹn/hồ sơ bệnh án)
        db.rollback()
        service.status = False
        db.commit()
        return {
            "message": "Service disabled successfully"
        }


@router.put("/{service_id}/price", response_model=ServiceResponse)
def update_price(
    service_id: int,
    new_price: float,
    db: Session = Depends(get_db)
):
    from services import pricing_service
    return pricing_service.update_service_price(db, service_id, new_price, None)


@router.get("/{service_id}/price-history", response_model=list[ServicePriceHistoryResponse])
def get_price_history(
    service_id: int,
    db: Session = Depends(get_db)
):
    from services import pricing_service
    return pricing_service.get_price_history(db, service_id)