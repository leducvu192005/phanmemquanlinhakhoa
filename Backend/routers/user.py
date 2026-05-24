from fastapi import APIRouter
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.database import SessionLocal

router=APIRouter()

@router.get("/patients")

def get_patients():

    db:Session=SessionLocal()

    result=db.execute(

        text(
        """

        SELECT
        id,
        full_name,
        email,
        phone,
        status

        FROM users

        WHERE role='patient'

        ORDER BY id

        """
        )

    )

    patients=[]

    for row in result:

        patients.append({

            "id":row.id,
            "full_name":row.full_name,
            "email":row.email,
            "phone":row.phone,
            "status":row.status

        })

    db.close()

    return patients