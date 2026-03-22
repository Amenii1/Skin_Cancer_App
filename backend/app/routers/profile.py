from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.dependencies import get_current_user, get_db
from app.models.utilisateur import Utilisateur
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue
from app.schemas.profile import ProfileUpdate
from fastapi import HTTPException

router = APIRouter(prefix="/profile", tags=["Profile"])

@router.get("/")
def get_profile(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    data = {
        "id": current_user.id,
        "nom": current_user.nom,
        "email": current_user.email,
        "role": current_user.role
    }

    # 🔥 حسب role
    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()

        if patient:
            data["patient_info"] = {
                "type_peau": patient.type_peau,
                "antecedents": patient.antecedents_familiaux
            }

    elif current_user.role == "doctor":
        doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()

        if doctor:
            data["doctor_info"] = {
                "specialite": doctor.specialite,
                "adresse": doctor.adresse_cabinet
            }

    return data


@router.put("/update")
def update_profile(
    data: ProfileUpdate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 🔹 update user
    if data.nom:
        current_user.nom = data.nom

    if data.email:
        # check email unique
        existing = db.query(Utilisateur).filter(Utilisateur.email == data.email).first()
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=400, detail="Email already used")

        current_user.email = data.email

    # 🔥 حسب role
    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()

        if patient:
            if data.type_peau:
                patient.type_peau = data.type_peau
            if data.antecedents_familiaux:
                patient.antecedents_familiaux = data.antecedents_familiaux

    elif current_user.role == "doctor":
        doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()

        if doctor:
            if data.specialite:
                doctor.specialite = data.specialite
            if data.adresse_cabinet:
                doctor.adresse_cabinet = data.adresse_cabinet

    db.commit()

    return {"message": "Profile updated successfully"}