from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
import os

from db import SessionLocal
from models.user import User
from models.doctor import Doctor

oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/auth/login"
)

from auth import SECRET_KEY, ALGORITHM


# =========================
# DATABASE
# =========================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# =========================
# CURRENT USER
# =========================
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={
            "WWW-Authenticate": "Bearer"
        },
    )

    try:
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM]
        )

        user_id = payload.get("sub")

        if user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(
        User.id == int(user_id)
    ).first()

    if user is None:
        raise credentials_exception

    return user


# =========================
# CURRENT ADMIN
# =========================
def get_current_admin(
    current_user: User = Depends(get_current_user)
):

    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin only"
        )

    return current_user


# =========================
# CURRENT DOCTOR
# =========================
def get_current_doctor(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Quyền hạn yêu cầu là Bác sĩ"
        )

    doctor = db.query(Doctor).filter(Doctor.email == current_user.email).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy thông tin Bác sĩ liên kết với tài khoản này"
        )

    return doctor