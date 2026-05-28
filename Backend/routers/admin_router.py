from fastapi import APIRouter, HTTPException, Depends
from typing import List, Optional
from db import SessionLocal
from models.user import User
from schemas.user import UserOut, UserUpdate, UserCreate
from auth import get_password_hash
from schemas.service import ServiceCreate, ServiceUpdate, ServiceResponse
from schemas.service_price_history import ServicePriceHistoryResponse
from services import service_management_service, pricing_service
from dependencies import get_db, get_current_admin

router = APIRouter()


@router.get('/users', response_model=List[UserOut])
def list_users(q: Optional[str] = None):
    db = SessionLocal()
    try:
        query = db.query(User)
        if q:
            like = f"%{q}%"
            query = query.filter((User.full_name.ilike(like)) | (User.email.ilike(like)))
        users = query.order_by(User.id).all()
        return users
    finally:
        db.close()


@router.post('/users', response_model=UserOut, status_code=201)
def create_user(payload: UserCreate):
    db = SessionLocal()

    try:
        # check existing email
        existing = db.query(User).filter(
            User.email == payload.email
        ).first()

        if existing:
            raise HTTPException(
                status_code=400,
                detail='Email already registered'
            )

        # hash password
        hashed = get_password_hash(
            payload.password
        )

        # create user
        user = User(
            email=payload.email,
            full_name=payload.full_name or "",
            password=hashed,
            phone=payload.phone,
            role=payload.role or "user",
            status=True
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        return user

    finally:
        db.close()

@router.get('/stats')
def stats():
    db = SessionLocal()
    try:
        total = db.query(User).count()
        active = db.query(User).filter(User.status == True).count()
        doctors = db.query(User).filter(User.role == 'doctor').count()
        receptionists = db.query(User).filter(User.role.ilike('%reception%') | (User.role == 'receptionist')).count()
        return {
            'total': total,
            'active': active,
            'doctors': doctors,
            'receptionists': receptionists,
        }
    finally:
        db.close()


@router.patch('/users/{user_id}', response_model=UserOut)
def update_user(user_id: int, payload: UserUpdate):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail='User not found')

        # update allowed fields
        if payload.full_name is not None:
            user.full_name = payload.full_name
        if payload.phone is not None:
            user.phone = payload.phone
        if payload.role is not None:
            user.role = payload.role
        if payload.status is not None:
            user.status = payload.status

        db.add(user)
        db.commit()
        db.refresh(user)
        return user
    finally:
        db.close()


@router.delete('/users/{user_id}', status_code=204)
def delete_user(user_id: int):
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail='User not found')
        db.delete(user)
        db.commit()
        return
    finally:
        db.close()


# === Service Management APIs ===
@router.get("/services", response_model=List[ServiceResponse], dependencies=[Depends(get_current_admin)])
def list_services(search: str = None, db=Depends(get_db)):
    return service_management_service.get_services(db, search)

@router.post("/services", response_model=ServiceResponse, dependencies=[Depends(get_current_admin)])
def create_service(service: ServiceCreate, db=Depends(get_db)):
    return service_management_service.create_service(db, service)

@router.put("/services/{service_id}", response_model=ServiceResponse, dependencies=[Depends(get_current_admin)])
def update_service(service_id: int, service: ServiceUpdate, db=Depends(get_db)):
    return service_management_service.update_service(db, service_id, service)

@router.delete("/services/{service_id}", response_model=ServiceResponse, dependencies=[Depends(get_current_admin)])
def delete_service(service_id: int, db=Depends(get_db)):
    return service_management_service.delete_service(db, service_id)

@router.put("/services/{service_id}/price", response_model=ServiceResponse, dependencies=[Depends(get_current_admin)])
def update_price(service_id: int, new_price: float, db=Depends(get_db), current_admin=Depends(get_current_admin)):
    return pricing_service.update_service_price(db, service_id, new_price, current_admin.id)

@router.get("/services/{service_id}/price-history", response_model=List[ServicePriceHistoryResponse], dependencies=[Depends(get_current_admin)])
def get_price_history(service_id: int, db=Depends(get_db)):
    return pricing_service.get_price_history(db, service_id)
