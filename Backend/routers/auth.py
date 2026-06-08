from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from datetime import timedelta

from models.user import User
from schemas.user import (
    UserCreate,
    UserOut,
    LoginSchema,
    TokenOut,
    UserUpdate,
)

from auth import (
    get_password_hash,
    verify_password,
    create_access_token,
)

from dependencies import get_current_user
from db import get_db

ACCESS_TOKEN_EXPIRE_MINUTES = 1440

router = APIRouter()
# =========================
# REGISTER
# =========================
@router.post(
    "/register",
    response_model=UserOut,
    status_code=status.HTTP_201_CREATED,
)
def register(
    payload: UserCreate,
    db: Session = Depends(get_db),
):
    email = payload.email.lower()

    existing_user = db.query(User).filter(
        User.email == email
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    hashed_password = get_password_hash(
        payload.password
    )

    new_user = User(
        username=payload.username,
        email=payload.email,
        phone=payload.phone,
        password=hashed_password,
        role="user",
        status=True
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user

# =========================
# LOGIN
# =========================
@router.post(
    "/login",
    response_model=TokenOut,
)
def login(
    payload: LoginSchema,
    db: Session = Depends(get_db),
):
    email = payload.email.lower()

    user = db.query(User).filter(
        User.email == email
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    if not user.status:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account disabled",
        )

    valid_password = verify_password(
        payload.password,
        user.password,
    )

    if not valid_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "role": user.role,
            "email": user.email,
        },
        expires_delta=timedelta(
            minutes=ACCESS_TOKEN_EXPIRE_MINUTES
        ),
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": user.role,
    }


# =========================
# CURRENT USER
# =========================
@router.get(
    "/me",
    response_model=UserOut,
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


# =========================
# UPDATE CURRENT USER
# =========================
@router.put(
    "/me",
    response_model=UserOut,
)
def update_me(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if payload.username is not None:
        current_user.username = payload.username
    if payload.phone is not None:
        current_user.phone = payload.phone
    if payload.email is not None:
        new_email = payload.email.lower()
        if new_email != current_user.email.lower():
            existing = db.query(User).filter(User.email == new_email).first()
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )
            current_user.email = new_email
            
    db.commit()
    db.refresh(current_user)
    return current_user