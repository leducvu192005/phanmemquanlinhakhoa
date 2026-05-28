from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
)

from db import Base


class User(Base):

    __tablename__ = "users"

    id = Column(
        Integer,
        primary_key=True,
        index=True
    )

    username = Column(
        String(100),
        nullable=False
    )

    email = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True
    )

    phone = Column(
        String(20),
        nullable=False
    )

    password = Column(
        String,
        nullable=False
    )

    role = Column(
        String(20),
        default="user"
    )

    status = Column(
        Boolean,
        default=True
    )