from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, String, DateTime, Integer, Boolean
from datetime import datetime

Base = declarative_base()


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, autoincrement=True)
    full_name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)  # stores hashed password
    phone = Column(String(20))
    role = Column(String(50), nullable=False, default='user')
    status = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
