from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from db import Base, engine
from routers.doctor_work_schedule_router import router as doctor_work_schedule
from routers.auth import router as auth_router
from routers.admin_router import router as admin_router
from routers.patients_router import router as patients_router
from routers.doctor_router import router as doctor_router
from routers.service import router as service_router
from routers.work_shift_router import router as work_shift_router
from routers.appointment_router import router as appointment_router
from routers.medical_record_router import router as medical_record_router
from routers.leave_request_router import router as leave_request_router
from routers.booking_router import router as booking_router
from routers.reports_router import router as reports_router
from routers.user import router as user_router
from routers.salary_router import router as salary_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Dental Clinic API",
    version="1.0.0"
)

# Tạo thư mục lưu trữ ảnh đại diện nếu chưa có
os.makedirs("static/avatars", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,

    allow_methods=["*"],
    allow_headers=["*"],
)

# Auth
app.include_router(
    auth_router,
    prefix="/auth",
    tags=["Auth"]
)

# Admin
app.include_router(
    admin_router,
    prefix="/admin",
    tags=["Admin"]
)

# Patients
app.include_router(
    patients_router,
    prefix="/patients",
    tags=["Patients"]
)

# Doctors
app.include_router(
    doctor_router
)

# Services
app.include_router(
    service_router
)

# Appointments
app.include_router(
    appointment_router
)

# Medical Records
app.include_router(
    medical_record_router
)

app.include_router(work_shift_router)
app.include_router(doctor_work_schedule)
app.include_router(leave_request_router)
app.include_router(booking_router)
app.include_router(reports_router)
app.include_router(user_router)
app.include_router(salary_router)
@app.get("/")
def home():
    return {
        "message": "Dental API Running 🚀"
    }