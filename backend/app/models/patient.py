from sqlalchemy import Column, Integer, String, ForeignKey, Float, Date
from sqlalchemy.orm import relationship
from app.core.database import Base


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, index=True)
    type_peau = Column(String, nullable=True)
    antecedents_familiaux = Column(String, nullable=True)
    ville = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    date_naissance = Column(Date, nullable=True)

    user = relationship("Utilisateur", back_populates="patient_profile")