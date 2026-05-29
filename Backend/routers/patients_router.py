from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from db import get_db
from models.patient import Patient
from schemas.patient import PatientOut

router = APIRouter(
    prefix="/patients",
)

@router.get("/", response_model=list[PatientOut])
def get_patients(db: Session = Depends(get_db)):
    return db.query(Patient).all()