from pydantic import BaseModel, EmailStr
from typing import Optional


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = 'user'


class UserOut(BaseModel):
    id: int
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    status: Optional[bool] = True
    role: Optional[str] = 'user'

    class Config:
        orm_mode = True


class LoginSchema(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str
    role: Optional[str]


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    status: Optional[bool] = None
