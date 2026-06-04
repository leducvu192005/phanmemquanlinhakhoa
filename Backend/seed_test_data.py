import os
import uuid
from datetime import datetime, date, time, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

from db import Base, engine, SessionLocal
from models.user import User
from models.doctor import Doctor
from models.patient import Patient
from models.service import Service
from models.appointment import Appointment
from auth import get_password_hash

# Tạo các bảng nếu chưa có
Base.metadata.create_all(bind=engine)

db = SessionLocal()

try:
    print("Bắt đầu khởi tạo dữ liệu giả lập...")

    # 1. Tạo dịch vụ mẫu
    services_data = [
        {"service_code": "DV001", "service_name": "Nhổ răng khôn", "category": "Tiểu phẫu", "duration_minutes": 45, "price": 1500000.0, "status": True},
        {"service_code": "DV002", "service_name": "Hàn composite", "category": "Nha khoa thẩm mỹ", "duration_minutes": 30, "price": 400000.0, "status": True},
        {"service_code": "DV003", "service_name": "Tẩy trắng răng Lazer", "category": "Nha khoa thẩm mỹ", "duration_minutes": 60, "price": 2500000.0, "status": True},
        {"service_code": "DV004", "service_name": "Cấy ghép Implant", "category": "Phục hình răng", "duration_minutes": 90, "price": 15000000.0, "status": True},
    ]

    services = []
    for s_item in services_data:
        existing = db.query(Service).filter(Service.service_code == s_item["service_code"]).first()
        if not existing:
            s = Service(**s_item)
            db.add(s)
            services.append(s)
            print(f"Đã tạo dịch vụ: {s.service_name}")
        else:
            services.append(existing)

    # 2. Tạo tài khoản Bác sĩ kiểm thử
    doc_email = "doctor@example.com"
    existing_user = db.query(User).filter(User.email == doc_email).first()
    if not existing_user:
        doc_user = User(
            username="Dr. Nguyen Van Binh",
            email=doc_email,
            phone="0911223344",
            password=get_password_hash("doctor123"),
            role="doctor",
            status=True
        )
        db.add(doc_user)
        db.commit()
        db.refresh(doc_user)
        print(f"Đã tạo tài khoản user cho Bác sĩ: {doc_email}")
    else:
        doc_user = existing_user

    # 3. Tạo hồ sơ bác sĩ trong bảng doctors
    existing_doc = db.query(Doctor).filter(Doctor.email == doc_email).first()
    if not existing_doc:
        # Kiểm tra mã code BS999 tránh trùng
        code = "BS999"
        doc_uuid = uuid.uuid4()
        doctor_profile = Doctor(
            id=doc_uuid,
            doctor_code=code,
            full_name="Nguyễn Văn Bình",
            gender="Nam",
            date_of_birth=date(1985, 5, 12),
            phone="0911223344",
            email=doc_email,
            specialty="Răng Hàm Mặt",
            qualification="Thạc sĩ, Bác sĩ chuyên khoa I",
            experience_years=12,
            address="123 Nguyễn Trãi, Quận 1, TP. HCM",
            bio="Bác sĩ có hơn 12 năm kinh nghiệm điều trị phục hình răng thẩm mỹ.",
            status=True
        )
        db.add(doctor_profile)
        db.commit()
        db.refresh(doctor_profile)
        print(f"Đã tạo hồ sơ bác sĩ: {doctor_profile.full_name} ({code})")
    else:
        doctor_profile = existing_doc

    # 4. Tạo bệnh nhân kiểm thử
    patient_data = [
        {"patient_code": "BN991", "full_name": "Trần Thị Ánh", "gender": "Nữ", "date_of_birth": date(1998, 10, 22), "phone": "0988776655", "email": "anh.tran@example.com", "address": "456 Lê Lợi, Quận 3, TP. HCM", "blood_type": "O", "allergies": "Dị ứng thuốc kháng sinh Penicillin", "medical_history": "Đã điều trị tủy răng số 46 năm 2024", "status": True},
        {"patient_code": "BN992", "full_name": "Lê Hoàng Long", "gender": "Nam", "date_of_birth": date(1992, 3, 15), "phone": "0977665544", "email": "long.le@example.com", "address": "789 Cách Mạng Tháng 8, Tân Bình, TP. HCM", "blood_type": "A", "allergies": None, "medical_history": "Huyết áp hơi cao", "status": True},
    ]

    patients = []
    for p_item in patient_data:
        existing_pat = db.query(Patient).filter(Patient.patient_code == p_item["patient_code"]).first()
        if not existing_pat:
            p = Patient(**p_item)
            db.add(p)
            patients.append(p)
            print(f"Đã tạo bệnh nhân: {p.full_name}")
        else:
            patients.append(existing_pat)

    # 5. Tạo lịch hẹn hôm nay cho Bác sĩ (ca trực hôm nay)
    today = date.today()
    db.commit() # Lưu tất cả thay đổi trên để lấy ID
    
    # Ca 1: 09:00 sáng
    time_1 = datetime.combine(today, time(9, 0))
    existing_app_1 = db.query(Appointment).filter(
        Appointment.doctor_id == doctor_profile.id,
        Appointment.appointment_time == time_1
    ).first()

    if not existing_app_1:
        app_1 = Appointment(
            patient_id=patients[0].id,
            doctor_id=doctor_profile.id,
            service_id=services[1].id, # Hàn composite
            appointment_time=time_1,
            status="confirmed",
            reason="Đau nhức răng hàm dưới khi uống nước lạnh",
            created_by=doc_user.id
        )
        db.add(app_1)
        print(f"Đã tạo lịch hẹn hôm nay lúc 09:00 cho {patients[0].full_name}")

    # Ca 2: 14:30 chiều
    time_2 = datetime.combine(today, time(14, 30))
    existing_app_2 = db.query(Appointment).filter(
        Appointment.doctor_id == doctor_profile.id,
        Appointment.appointment_time == time_2
    ).first()

    if not existing_app_2:
        app_2 = Appointment(
            patient_id=patients[1].id,
            doctor_id=doctor_profile.id,
            service_id=services[0].id, # Nhổ răng khôn
            appointment_time=time_2,
            status="pending",
            reason="Khám nhổ răng khôn số 38 mọc lệch",
            created_by=doc_user.id
        )
        db.add(app_2)
        print(f"Đã tạo lịch hẹn hôm nay lúc 14:30 cho {patients[1].full_name}")

    db.commit()
    print("Khởi tạo dữ liệu kiểm thử hoàn tất thành công! 🎉")
    print(f"-> Đăng nhập Bác sĩ: Email: {doc_email} / Mật khẩu: doctor123")

except Exception as e:
    db.rollback()
    print(f"Lỗi khi khởi tạo dữ liệu: {e}")
finally:
    db.close()
