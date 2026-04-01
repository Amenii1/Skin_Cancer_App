from typing import Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.avis import Avis
from app.models.dermatologue import Dermatologue
from app.models.image import Image
from app.models.utilisateur import Utilisateur

router = APIRouter(prefix="/avis", tags=["Avis"])


class AvisPayload(BaseModel):
    commentaire: str
    diagnostic: str


@router.post("/{image_id}")
def give_avis(
    image_id: int,
    rating: int,
    commentaire: Optional[str] = Query(default=None),
    diagnostic: Optional[str] = Query(default=None),
    payload: Optional[AvisPayload] = Body(default=None),
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

    final_commentaire = commentaire or (payload.commentaire if payload else None)
    final_diagnostic = diagnostic or (payload.diagnostic if payload else None)
    if not final_commentaire or not final_diagnostic:
        raise HTTPException(
            status_code=400,
            detail="commentaire and diagnostic are required",
        )

    new_avis = Avis(
        image_id=image_id,
        dermatologue_id=doctor.id,
        commentaire=final_commentaire,
        diagnostic=final_diagnostic,
    )

    db.add(new_avis)
    db.commit()
    db.refresh(new_avis)

    return {"message": "Avis added"}

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
            result.append({
                "avis_id": avis.id,
                "image_id": img.id,
                "commentaire": avis.commentaire,
                "diagnostic": avis.diagnostic,
                "doctor_id": avis.dermatologue_id,
            })

    return result

@router.get("/doctor")
def get_doctor_avis(
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
        patient_name = None
        patient_email = None
        if img:
            user = db.query(Utilisateur).filter(Utilisateur.id == img.user_id).first()
            if user:
                patient_name = user.nom
                patient_email = user.email
        out.append(
            {
                "id": a.id,
                "image_id": a.image_id,
                "dermatologue_id": a.dermatologue_id,
                "commentaire": a.commentaire,
                "diagnostic": a.diagnostic,
                "patient_name": patient_name,
                "patient_email": patient_email,
                "image_path": img.path if img else None,
                "result": img.result if img else None,
                "confidence": img.confidence if img else None,
                "observation_date": img.observation_date.isoformat()
                if img and img.observation_date
                else None,
            }
        )
    return out

