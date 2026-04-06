from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.core.dependencies import get_current_user, get_db
from app.models.utilisateur import Utilisateur
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue
from app.models.reservation import Reservation
from app.models.disponibilite import Disponibilite
from app.models.avis import Avis
from app.models.image import Image

router = APIRouter(prefix="/doctor", tags=["Doctor"])

@router.get("/patients")
def get_doctor_patients(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    # Patients from reservations (only accepted)
    patient_ids_res = [
        r.patient_id
        for r in db.query(Reservation)
        .join(Disponibilite)
        .filter(
            Disponibilite.dermatologue_id == doctor.id,
            Reservation.status == "accepted"
        )
        .all()
    ]

    # Patients from avis (opinions)
    patient_ids_avis = [
        img.user_id
        for img in db.query(Image)
        .join(Avis)
        .filter(Avis.dermatologue_id == doctor.id)
        .all()
    ]

    # Map user_id from avis to patient_id if needed, but let's assume we want to return patient objects
    # First get patient objects for those in patient_ids_res
    patients_res = db.query(Patient).filter(Patient.id.in_(patient_ids_res)).all()
    
    # Then get patient objects for those user_ids in patient_ids_avis
    patients_avis = db.query(Patient).filter(Patient.user_id.in_(patient_ids_avis)).all()

    # Merge and deduplicate
    all_patients = {p.id: p for p in patients_res + patients_avis}.values()

    out = []
    for p in all_patients:
        user = db.query(Utilisateur).filter(Utilisateur.id == p.user_id).first()
        # Get lesion count for this patient
        lesion_count = db.query(Image).filter(Image.user_id == p.user_id).count()
        # Get highest risk level
        images = db.query(Image).filter(Image.user_id == p.user_id).all()
        risk = "Faible"
        risk_color = "low"
        for img in images:
            if img.result == "melanoma":
                risk = "Élevé"
                risk_color = "high"
                break
            elif img.result and ("carcinoma" in img.result.lower() or "basal" in img.result.lower()):
                risk = "Modéré"
                risk_color = "medium"

        out.append({
            "id": p.id,
            "name": user.nom if user else "Inconnu",
            "email": user.email if user else None,
            "phone": user.telephone if user else None,
            "ville": p.ville,
            "lesion_count": lesion_count,
            "risk_level": risk,
            "risk_color": risk_color,
            "last_visit": "À implémenter", # Could be last reservation date
        })

    return out
