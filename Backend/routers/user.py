from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from db import get_db
from models.user import User
from schemas.user import UserRoleOut, UserRoleUpdate
from dependencies import get_current_user

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

@router.get("/", response_model=List[UserRoleOut])
def get_all_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Authorization: Only Admins can view the user list
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập danh sách tài khoản"
        )

    users = db.query(User).order_by(User.id.asc()).all()

    res = []
    for u in users:
        # Map DB role ('user' or 'patient') to output role 'patient' for UI consistency
        out_role = "patient" if u.role in ["user", "patient"] else u.role

        res.append(UserRoleOut(
            id=u.id,
            full_name=u.username,  # username stores full name
            email=u.email,
            role=out_role,
            is_active=u.status   # status is mapping to is_active
        ))
    return res

@router.put("/{user_id}/role", response_model=UserRoleOut)
def update_user_role(
    user_id: int,
    payload: UserRoleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Authorization: Only Admins can modify account roles
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền thay đổi phân quyền tài khoản"
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy tài khoản"
        )

    # Validate target role
    new_role = payload.role.lower()
    valid_roles = ["admin", "staff", "doctor", "patient"]
    if new_role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Vai trò không hợp lệ. Phải thuộc: {', '.join(valid_roles)}"
        )

    # Map 'patient' to 'user' for DB storage compatibility
    db_role = "user" if new_role == "patient" else new_role

    # Security Rule 1: Admin cannot demote themselves
    if user.id == current_user.id and db_role != "admin":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không thể tự hạ phân quyền của chính mình"
        )

    # Security Rule 2: Cannot demote the last active admin
    if user.role == "admin" and db_role != "admin":
        active_admin_count = db.query(User).filter(User.role == "admin", User.status == True).count()
        if active_admin_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Không thể thay đổi phân quyền của tài khoản Admin duy nhất đang hoạt động trong hệ thống"
            )

    user.role = db_role
    db.commit()
    db.refresh(user)

    out_role = "patient" if user.role in ["user", "patient"] else user.role
    return UserRoleOut(
        id=user.id,
        full_name=user.username,
        email=user.email,
        role=out_role,
        is_active=user.status
    )