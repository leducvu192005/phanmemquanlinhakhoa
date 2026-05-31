from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from db import Base, engine
from routers.doctor_work_schedule_router import router as doctor_work_schedule
from routers.auth import router as auth_router
from routers.admin_router import router as admin_router
from routers.patients_router import router as patients_router
from routers.doctor_router import router as doctor_router
from routers.service import router as service_router
from routers.work_shift_router import router as work_shift_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Dental Clinic API",
    version="1.0.0"
)

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
    prefix="/admin/patients",
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

app.include_router(work_shift_router)
app.include_router(doctor_work_schedule)
@app.get("/")
def home():
    return {
        "message": "Dental API Running 🚀"
    }