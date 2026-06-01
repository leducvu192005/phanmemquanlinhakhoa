from datetime import datetime, timedelta
from jose import jwt
from passlib.context import CryptContext
from dotenv import load_dotenv
import os

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY", "super-secret-key")
ALGORITHM = "HS256"

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)

def get_password_hash(password: str):
    return pwd_context.hash(password[:72])

def verify_password(
    plain_password: str,
    hashed_password: str
):
    return pwd_context.verify(
    plain_password.encode("utf-8")[:72].decode(
    "utf-8",    
    errors="ignore"
),
        hashed_password
    )

def create_access_token(
    data: dict,
    expires_delta: timedelta = None
):
    to_encode = data.copy()

    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=1440)

    to_encode.update({
        "exp": expire
    })

    encoded_jwt = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return encoded_jwt