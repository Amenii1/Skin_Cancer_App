from sqlalchemy import Boolean, Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base


class Utilisateur(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    nom = Column(String)
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)
    role = Column(String)
    is_active = Column(Boolean, nullable=False, default=True, server_default="1")
    telephone = Column(String, nullable=True)
    reset_code = Column(String, nullable=True)
    reset_code_expires_at = Column(DateTime, nullable=True)

    patient_profile = relationship(
        "Patient", back_populates="user", uselist=False
    )
    dermatologue = relationship(
        "Dermatologue", back_populates="user", uselist=False
    )
    notifications = relationship(
        "Notification", back_populates="user", cascade="all, delete-orphan"
    )
