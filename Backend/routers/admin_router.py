from fastapi import APIRouter, HTTPException
from typing import List, Optional
from db import SessionLocal
from models import User
from schemas import UserOut, UserUpdate, UserCreate
from auth import get_password_hash

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
        existing = db.query(User).filter(User.email == payload.email).first()
        if existing:
            raise HTTPException(status_code=400, detail='Email already registered')

        hashed = get_password_hash(payload.password)
        user = User(
            email=payload.email,
            full_name=payload.full_name or '',
            password=hashed,
            phone=payload.phone,
            role=payload.role or 'user',
            status=True,
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
