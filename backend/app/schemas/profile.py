from pydantic import BaseModel
from typing import Optional

class ProfileUpdate(BaseModel):
    nom: Optional[str] = None
    email: Optional[str] = None

    # patient
    type_peau: Optional[str] = None
    antecedents_familiaux: Optional[str] = None

    # doctor
    specialite: Optional[str] = None
    adresse_cabinet: Optional[str] = None