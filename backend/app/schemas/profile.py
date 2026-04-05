from pydantic import BaseModel
from typing import Optional


class ProfileUpdate(BaseModel):
    nom: Optional[str] = None
    email: Optional[str] = None
    telephone: Optional[str] = None

    # patient
    date_naissance: Optional[str] = None  # YYYY-MM-DD
    ville: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    type_peau: Optional[str] = None
    antecedents_familiaux: Optional[str] = None

    # doctor
    specialite: Optional[str] = None
    adresse_cabinet: Optional[str] = None
    numero_rpps: Optional[str] = None
