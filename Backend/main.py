from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from db import Base, engine

from routers.auth import router as auth_router
from routers.admin_router import router as admin_router
from routers.patients_router import router as patients_router

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Dental Clinic API",
    version="1.0.0"
)

# ======================
# CORS CONFIG
# ======================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ======================
# ROUTERS
# ======================

# Auth routes
app.include_router(
    auth_router,
    prefix="/auth",
    tags=["Auth"]
)

# Admin routes (users, services, stats,...)
app.include_router(
    admin_router,
    prefix="/admin",
    tags=["Admin"]
)

# Patients routes)
app.include_router(
    patients_router,
    prefix="/admin/patients",  
    tags=["Patients"]
)

# ======================
# HEALTH CHECK
# ======================
@app.get("/")
def home():
    return {
        "message": "Dental API Running 🚀"
    }