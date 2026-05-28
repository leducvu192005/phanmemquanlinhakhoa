from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from db import Base, engine

from routers.auth import (
    router as auth_router
)

Base.metadata.create_all(bind=engine)

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth_router)


@app.get("/")
def home():
    return {
        "message": "Dental API Running"
    }