from datetime import date, datetime
import uuid
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_

from db import SessionLocal
from models.leave_request import LeaveRequest
from models.doctor import Doctor
from models.user import User
from schemas.leave_request import (
    LeaveRequestCreate,
    LeaveRequestUpdate,
    LeaveRequestResponse
)
from dependencies import get_db, get_current_user

router = APIRouter(
    prefix="/leave-requests",
    tags=["Leave Requests"]
)


def get_db_local():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def _format_leave_request(req: LeaveRequest, db: Session) -> LeaveRequestResponse:
    user_name = None
    user_email = None
    user_role = None

    usr = db.query(User).filter(User.id == req.user_id).first()
    if usr:
        user_email = usr.email
        user_role = usr.role
        if usr.role == "doctor":
            # Nếu là bác sĩ, cố gắng lấy tên đầy đủ từ bảng doctors
            doc = db.query(Doctor).filter(Doctor.email == usr.email).first()
            user_name = doc.full_name if doc else usr.username
        else:
            user_name = usr.username
            
    approved_by_name = None
    if req.approved_by:
        appr = db.query(User).filter(User.id == req.approved_by).first()
        if appr:
            approved_by_name = appr.username

    return LeaveRequestResponse(
        id=req.id,
        request_code=req.request_code,
        user_id=req.user_id,
        user_name=user_name,
        user_email=user_email,
        user_role=user_role,
        start_date=req.start_date,
        end_date=req.end_date,
        leave_type=req.leave_type,
        reason=req.reason,
        status=req.status,
        created_at=req.created_at,
        approved_by=req.approved_by,
        approved_by_name=approved_by_name,
        approved_at=req.approved_at,
        reject_reason=req.reject_reason
    )


# ==========================================
# TẠO YÊU CẦU NGHỈ PHÉP (Doctor hoặc Staff tự tạo cho mình)
# ==========================================
@router.post("/", response_model=LeaveRequestResponse)
def create_leave_request(
    body: LeaveRequestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db_local)
):
    # 1. end_date < start_date
    if body.end_date < body.start_date:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ngày kết thúc không được nhỏ hơn ngày bắt đầu."
        )
        
    # 2. start_date in the past
    if body.start_date < date.today():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không được đăng ký nghỉ phép trong quá khứ."
        )
        
    # 3. Trùng thời gian với yêu cầu đã APPROVED
    overlapping = (
        db.query(LeaveRequest)
        .filter(
            LeaveRequest.user_id == current_user.id,
            LeaveRequest.status == "Approved",
            LeaveRequest.start_date <= body.end_date,
            LeaveRequest.end_date >= body.start_date
        )
        .first()
    )
    if overlapping:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Trùng thời gian với yêu cầu nghỉ phép đã được duyệt ({overlapping.start_date} đến {overlapping.end_date})."
        )

    # 4. Tạo mã yêu cầu duy nhất
    req_code = f"LR-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:4].upper()}"
    
    new_req = LeaveRequest(
        request_code=req_code,
        user_id=current_user.id,
        start_date=body.start_date,
        end_date=body.end_date,
        leave_type=body.leave_type,
        reason=body.reason,
        status="Pending"
    )
    
    db.add(new_req)
    db.commit()
    db.refresh(new_req)
    
    return _format_leave_request(new_req, db)


# ==========================================
# LẤY DANH SÁCH YÊU CẦU NGHỈ PHÉP
# ==========================================
@router.get("/", response_model=List[LeaveRequestResponse])
def get_leave_requests(
    status_filter: Optional[str] = Query(None, alias="status"),
    own: bool = Query(False),
    db: Session = Depends(get_db_local),
    current_user: User = Depends(get_current_user)
):
    query = db.query(LeaveRequest)
    
    # Nếu là doctor hoặc tham số own = True, chỉ hiển thị của bản thân
    if current_user.role == "doctor" or own:
        query = query.filter(LeaveRequest.user_id == current_user.id)
    else:
        # Staff/Admin xem danh sách của người khác để duyệt
        # Có thể tùy ý lọc theo trạng thái
        pass
        
    if status_filter:
        query = query.filter(LeaveRequest.status == status_filter)
        
    requests = query.order_by(LeaveRequest.created_at.desc()).all()
    return [_format_leave_request(r, db) for r in requests]


# ==========================================
# LẤY THỐNG KÊ YÊU CẦU NGHỈ PHÉP
# ==========================================
@router.get("/stats")
def get_leave_stats(
    own: bool = Query(False),
    db: Session = Depends(get_db_local),
    current_user: User = Depends(get_current_user)
):
    query = db.query(LeaveRequest)
    
    if current_user.role == "doctor" or own:
        query = query.filter(LeaveRequest.user_id == current_user.id)
        
    total = query.count()
    pending = query.filter(LeaveRequest.status == "Pending").count()
    approved = query.filter(LeaveRequest.status == "Approved").count()
    rejected = query.filter(LeaveRequest.status == "Rejected").count()
    
    return {
        "total": total,
        "pending": pending,
        "approved": approved,
        "rejected": rejected
    }


# ==========================================
# HỦY YÊU CẦU (Chỉ khi Pending)
# ==========================================
@router.put("/{request_id}/cancel", response_model=LeaveRequestResponse)
def cancel_leave_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db_local)
):
    req = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not req:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy yêu cầu nghỉ phép."
        )
        
    if req.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền hủy yêu cầu nghỉ phép của người khác."
        )
        
    if req.status != "Pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Chỉ có thể hủy yêu cầu nghỉ phép ở trạng thái Chờ duyệt (Pending)."
        )
        
    req.status = "Cancelled"
    db.commit()
    db.refresh(req)
    
    return _format_leave_request(req, db)


# ==========================================
# STAFF/ADMIN DUYỆT YÊU CẦU
# ==========================================
@router.put("/{request_id}/approve", response_model=LeaveRequestResponse)
def approve_leave_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db_local)
):
    if current_user.role == "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bác sĩ không có quyền phê duyệt yêu cầu nghỉ phép."
        )
        
    req = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not req:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy yêu cầu nghỉ phép."
        )
        
    if req.user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không thể tự phê duyệt yêu cầu nghỉ phép của chính mình."
        )
        
    if req.status != "Pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Chỉ có thể phê duyệt yêu cầu nghỉ phép ở trạng thái Chờ duyệt (Pending)."
        )
        
    req.status = "Approved"
    req.approved_by = current_user.id
    req.approved_at = datetime.now()
    
    db.commit()
    db.refresh(req)
    
    return _format_leave_request(req, db)


# ==========================================
# STAFF/ADMIN TỪ CHỐI YÊU CẦU KÈM LÝ DO
# ==========================================
@router.put("/{request_id}/reject", response_model=LeaveRequestResponse)
def reject_leave_request(
    request_id: int,
    body: LeaveRequestUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db_local)
):
    if current_user.role == "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bác sĩ không có quyền từ chối yêu cầu nghỉ phép."
        )
        
    req = db.query(LeaveRequest).filter(LeaveRequest.id == request_id).first()
    if not req:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy yêu cầu nghỉ phép."
        )
        
    if req.user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Không thể từ chối yêu cầu nghỉ phép của chính mình."
        )
        
    if req.status != "Pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Chỉ có thể từ chối yêu cầu nghỉ phép ở trạng thái Chờ duyệt (Pending)."
        )
        
    req.status = "Rejected"
    req.approved_by = current_user.id
    req.approved_at = datetime.now()
    req.reject_reason = body.reject_reason or "Không có lý do chi tiết."
    
    db.commit()
    db.refresh(req)
    
    return _format_leave_request(req, db)
