# app/schemas/disponibilite.py
from pydantic import BaseModel
from datetime import date, time

class DisponibiliteCreate(BaseModel):
    date: date
    heure_debut: time
    heure_fin: time