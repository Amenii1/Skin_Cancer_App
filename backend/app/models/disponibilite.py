# app/models/disponibilite.py
from sqlalchemy import Column, Integer, ForeignKey, Date, Time, Boolean
from app.core.database import Base

class Disponibilite(Base):
    __tablename__ = "disponibilites"

    id = Column(Integer, primary_key=True, index=True)
    dermatologue_id = Column(Integer, ForeignKey("dermatologues.id"))

    date = Column(Date, nullable=False)
    heure_debut = Column(Time, nullable=False)
    heure_fin = Column(Time, nullable=False)

    is_reserved = Column(Boolean, default=False)