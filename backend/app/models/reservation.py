from sqlalchemy import Column, Integer, ForeignKey, DateTime, String
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Reservation(Base):
    __tablename__ = "reservations"

    id = Column(Integer, primary_key=True, index=True)

    patient_id = Column(Integer, ForeignKey("patients.id"))
    disponibilite_id = Column(Integer, ForeignKey("disponibilites.id"))

    date_rdv = Column(DateTime, nullable=False)
    status = Column(String, default="pending")  # pending / accepted / refused

    # relations
    patient = relationship("Patient")
    disponibilite = relationship("Disponibilite")