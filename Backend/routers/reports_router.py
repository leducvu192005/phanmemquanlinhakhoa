from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, date

from db import get_db
from models.booking import Booking
from models.doctor import Doctor
from models.patient import Patient
from dependencies import get_current_user
from models.user import User

router = APIRouter(
    prefix="/reports",
    tags=["Reports"]
)

def parse_services_for_symptoms(symptoms: str) -> list:
    s = (symptoms or '').lower()
    services = []
    # Always include consultation fee
    services.append({"name": "Khám & tư vấn răng hàm mặt", "price": 100000.0})

    if 'nhổ' in s or 'răng khôn' in s or 'răng lệch' in s:
        services.append({"name": "Chụp phim panorama toàn cảnh", "price": 350000.0})
        services.append({"name": "Nhổ răng khôn mọc lệch (tiểu phẫu)", "price": 1500000.0})
    elif 'trám' in s or 'sâu' in s or 'đau' in s:
        services.append({"name": "Chụp phim quanh chóp (X-Quang)", "price": 200000.0})
        services.append({"name": "Trám răng composite thẩm mỹ", "price": 500000.0})
    elif 'tẩy' in s or 'trắng' in s or 'cao răng' in s or 'vôi' in s:
        services.append({"name": "Lấy cao răng & đánh bóng hai hàm", "price": 250000.0})
        if 'tẩy' in s or 'trắng' in s:
            services.append({"name": "Tẩy trắng răng thẩm mỹ tại phòng khám", "price": 2000000.0})
    else:
        services.append({"name": "Lấy cao răng & đánh bóng hai hàm", "price": 250000.0})

    return services

@router.get("/revenue")
def get_revenue_report(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Authorization: Only Admin is allowed to access revenue reports
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập chức năng thống kê doanh thu"
        )

    # 1. Fetch all paid bookings for overall KPI cards (overall, today, this month)
    all_paid_bookings = db.query(Booking).filter(Booking.payment_status == "paid").all()

    today_str = date.today().strftime("%Y-%m-%d")
    current_month_prefix = date.today().strftime("%Y-%m")

    total_revenue = 0.0
    today_revenue = 0.0
    month_revenue = 0.0
    total_paid_bookings = len(all_paid_bookings)

    for b in all_paid_bookings:
        # Net revenue = total_amount (which is subtotal - discount_amount)
        rev = b.total_amount
        total_revenue += rev
        
        # Determine payment date string
        b_date = b.booking_date
        if b.payment_time:
            # Format in local timezone (we format direct date representation)
            b_date = b.payment_time.strftime("%Y-%m-%d")

        if b_date == today_str:
            today_revenue += rev
        if b_date.startswith(current_month_prefix):
            month_revenue += rev

    # 2. Query paid bookings filtered by start_date and end_date
    query = db.query(Booking).filter(Booking.payment_status == "paid")
    if start_date:
        query = query.filter(Booking.booking_date >= start_date)
    if end_date:
        query = query.filter(Booking.booking_date <= end_date)

    filtered_bookings = query.order_by(Booking.id.desc()).all()

    # 3. Calculate daily revenue breakdown
    daily_map = {}
    for b in filtered_bookings:
        b_date = b.booking_date
        if b.payment_time:
            b_date = b.payment_time.strftime("%Y-%m-%d")
        daily_map[b_date] = daily_map.get(b_date, 0.0) + b.total_amount

    daily_revenue = [{"date": k, "revenue": v} for k, v in sorted(daily_map.items())]

    # 4. Calculate doctor revenue breakdown
    doctor_map = {}
    for b in filtered_bookings:
        doc_name = b.doctor.full_name if b.doctor else "Bác sĩ chưa xác định"
        if doc_name not in doctor_map:
            doctor_map[doc_name] = {"count": 0, "revenue": 0.0}
        doctor_map[doc_name]["count"] += 1
        doctor_map[doc_name]["revenue"] += b.total_amount

    doctor_revenue = [
        {
            "doctorName": k,
            "bookingCount": v["count"],
            "revenue": v["revenue"]
        }
        for k, v in doctor_map.items()
    ]
    # Sort doctor revenue by revenue descending
    doctor_revenue.sort(key=lambda x: x["revenue"], reverse=True)

    # 5. Calculate service revenue breakdown
    service_map = {}
    for b in filtered_bookings:
        services = parse_services_for_symptoms(b.symptoms)
        # Note: Since discount is applied globally to a booking, we calculate service revenue
        # based on their list price, or if we want to be simple, we use the service's subtotal price.
        # Let's sum up the service subtotals.
        for svc in services:
            svc_name = svc["name"]
            svc_price = svc["price"]
            if svc_name not in service_map:
                service_map[svc_name] = {"count": 0, "revenue": 0.0}
            service_map[svc_name]["count"] += 1
            service_map[svc_name]["revenue"] += svc_price

    service_revenue = [
        {
            "serviceName": k,
            "count": v["count"],
            "revenue": v["revenue"]
        }
        for k, v in service_map.items()
    ]
    # Sort service revenue by revenue descending
    service_revenue.sort(key=lambda x: x["revenue"], reverse=True)

    # 6. Detail list of transactions
    transactions_list = []
    for b in filtered_bookings:
        transactions_list.append({
            "bookingId": f"LH-{b.id}",
            "patientName": b.patient.full_name if b.patient else "Bệnh nhân ẩn danh",
            "doctorName": b.doctor.full_name if b.doctor else "Bác sĩ",
            "paymentTime": b.payment_time.isoformat() if b.payment_time else b.created_at.isoformat(),
            "paymentMethod": b.payment_method or "Chưa rõ",
            "discountAmount": b.discount_amount,
            "totalAmount": b.total_amount
        })

    return {
        "totalRevenue": total_revenue,
        "todayRevenue": today_revenue,
        "monthRevenue": month_revenue,
        "totalPaidBookings": total_paid_bookings,
        "dailyRevenue": daily_revenue,
        "doctorRevenue": doctor_revenue,
        "serviceRevenue": service_revenue,
        "transactions": transactions_list
    }
