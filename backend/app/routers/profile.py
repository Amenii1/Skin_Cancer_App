from datetime import date

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.utilisateur import Utilisateur
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue
from app.schemas.profile import ProfileUpdate

router = APIRouter(prefix="/profile", tags=["Profile"])


@router.get("/")
def get_profile(
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    data = {
        "id": current_user.id,
        "nom": current_user.nom,
        "email": current_user.email,
        "role": current_user.role,
        "is_active": getattr(current_user, "is_active", True),
        "telephone": current_user.telephone,
    }

    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
        if patient:
            data["patient_info"] = {
                "type_peau": patient.type_peau,
                "antecedents": patient.antecedents_familiaux,
                "ville": patient.ville,
                "latitude": patient.latitude,
                "longitude": patient.longitude,
                "date_naissance": patient.date_naissance.isoformat()
                if patient.date_naissance
                else None,
            }

    elif current_user.role == "doctor":
        doctor = (
            db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
        )
        if doctor:
            data["doctor_info"] = {
                "specialite": doctor.specialite,
                "adresse": doctor.adresse_cabinet,
                "ville": doctor.ville,
                "latitude": doctor.latitude,
                "longitude": doctor.longitude,
                "numero_rpps": doctor.numero_rpps,
            }

    return data


@router.put("/update")
def update_profile(
    data: ProfileUpdate,
    current_user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if data.nom:
        current_user.nom = data.nom

    if data.email:
        existing = (
            db.query(Utilisateur).filter(Utilisateur.email == data.email).first()
        )
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email already used")
        current_user.email = data.email

    if data.telephone is not None:
        current_user.telephone = data.telephone

    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
        if patient:
            if data.date_naissance is not None:
                if data.date_naissance.strip() == "":
                    patient.date_naissance = None
                else:
                    try:
                        patient.date_naissance = date.fromisoformat(
                            data.date_naissance.strip()
                        )
                    except ValueError:
                        raise HTTPException(
                            status_code=400,
                            detail="date_naissance must be YYYY-MM-DD",
                        )
            if data.type_peau is not None:
                patient.type_peau = data.type_peau
            if data.antecedents_familiaux is not None:
                patient.antecedents_familiaux = data.antecedents_familiaux
            if data.ville is not None:
                patient.ville = data.ville
            if data.latitude is not None:
                patient.latitude = data.latitude
            if data.longitude is not None:
                patient.longitude = data.longitude

    elif current_user.role == "doctor":
        doctor = (
            db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
        )
        if doctor:
            if data.specialite is not None:
                doctor.specialite = data.specialite
            if data.adresse_cabinet is not None:
                doctor.adresse_cabinet = data.adresse_cabinet
            if data.ville is not None:
                doctor.ville = data.ville
            if data.latitude is not None:
                doctor.latitude = data.latitude
            if data.longitude is not None:
                doctor.longitude = data.longitude
            if data.numero_rpps is not None:
                doctor.numero_rpps = data.numero_rpps

    db.commit()

    return {"message": "Profile updated successfully"}
