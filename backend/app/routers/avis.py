import os

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.avis import Avis
from app.models.dermatologue import Dermatologue
from app.models.image import Image
from app.models.patient import Patient
from app.models.utilisateur import Utilisateur
from app.services.notification_service import create_doctor_avis_notification

router = APIRouter(prefix="/avis", tags=["Avis"])


class AvisCreate(BaseModel):
    commentaire: str
    diagnostic: str = "Avis dermatologue"
    rating: int = Field(default=5, ge=1, le=5)


@router.post("/{image_id}")
def give_avis(
    image_id: int,
    payload: AvisCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can give avis")

    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    image = db.query(Image).filter(Image.id == image_id).first()

    if not image:
        raise HTTPException(status_code=404, detail="Image not found")

    existing = (
        db.query(Avis)
        .filter(
            Avis.image_id == image_id,
            Avis.dermatologue_id == doctor.id,
        )
        .first()
    )
    if existing:
        existing.commentaire = payload.commentaire
        existing.diagnostic = payload.diagnostic
        existing.rating = payload.rating
        create_doctor_avis_notification(
            db,
            image=image,
            doctor=doctor,
            is_update=True,
        )
        db.commit()
        db.refresh(existing)
        return {"message": "Avis updated", "avis_id": existing.id}

    new_avis = Avis(
        image_id=image_id,
        dermatologue_id=doctor.id,
        commentaire=payload.commentaire,
        diagnostic=payload.diagnostic,
        rating=payload.rating,
    )

    db.add(new_avis)
    create_doctor_avis_notification(
        db,
        image=image,
        doctor=doctor,
        is_update=False,
    )
    db.commit()
    db.refresh(new_avis)

    return {"message": "Avis added", "avis_id": new_avis.id}


@router.get("/my")
def get_my_avis(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):

    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients")

    images = db.query(Image).filter(Image.user_id == current_user.id).all()

    result = []

    for img in images:
        for avis in img.avis:
            result.append(
                {
                    "avis_id": avis.id,
                    "image_id": img.id,
                    "commentaire": avis.commentaire,
                    "diagnostic": avis.diagnostic,
                    "doctor_id": avis.dermatologue_id,
                }
            )

    return result


@router.get("/doctor")
def get_doctor_avis(
    request: Request,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    rows = db.query(Avis).filter(Avis.dermatologue_id == doctor.id).all()
    out = []
    for a in rows:
        img = db.query(Image).filter(Image.id == a.image_id).first()
        patient_id = None
        patient_name = None
        patient_email = None
        image_url = None
        if img:
            user = db.query(Utilisateur).filter(Utilisateur.id == img.user_id).first()
            patient = db.query(Patient).filter(Patient.user_id == img.user_id).first()
            if user:
                patient_name = user.nom
                patient_email = user.email
            if patient:
                patient_id = patient.id
            image_url = f"{request.base_url}uploads/{os.path.basename(img.path)}"
        out.append(
            {
                "id": a.id,
                "image_id": a.image_id,
                "patient_id": patient_id,
                "dermatologue_id": a.dermatologue_id,
                "commentaire": a.commentaire,
                "diagnostic": a.diagnostic,
                "patient_name": patient_name,
                "patient_email": patient_email,
                "image_path": img.path if img else None,
                "image_url": image_url,
                "result": img.result if img else None,
                "confidence": img.confidence if img else None,
                "observation_date": img.observation_date.isoformat()
                if img and img.observation_date
                else None,
            }
        )
    return out
