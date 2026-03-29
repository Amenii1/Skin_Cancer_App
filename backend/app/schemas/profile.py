from pydantic import BaseModel
from typing import Optional


class ProfileUpdate(BaseModel):
    nom: Optional[str] = None
    email: Optional[str] = None

    # patient : domicile pour « proches » ; doctor : localisation du cabinet
    ville: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    type_peau: Optional[str] = None
    antecedents_familiaux: Optional[str] = None

    specialite: Optional[str] = None
    adresse_cabinet: Optional[str] = None
