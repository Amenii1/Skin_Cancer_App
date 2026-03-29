from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, get_current_user
from app.models.avis import Avis
from app.models.dermatologue import Dermatologue
from app.models.image import Image

router = APIRouter(prefix="/avis", tags=["Avis"])


# 👨‍⚕️ doctor يعطي avis
@router.post("/{image_id}")
def give_avis(image_id: int,
              commentaire: str,
              diagnostic: str,
              db: Session = Depends(get_db),
              current_user = Depends(get_current_user)):

    # 🔥 check doctor
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors can give avis")

    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    image = db.query(Image).filter(Image.id == image_id).first()

    if not image:
        raise HTTPException(status_code=404, detail="Image not found")

    new_avis = Avis(
        image_id=image_id,
        dermatologue_id=doctor.id,
        commentaire=commentaire,
        diagnostic=diagnostic
    )

    db.add(new_avis)
    db.commit()
    db.refresh(new_avis)

    return {"message": "Avis added"}

@router.get("/my")
def get_my_avis(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):

    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients")

    images = db.query(Image).filter(Image.user_id == current_user.id).all()

    result = []

    for img in images:
        for avis in img.avis:
            result.append({
                "image_id": img.id,
                "commentaire": avis.commentaire,
                "diagnostic": avis.diagnostic,
                "doctor_id": avis.dermatologue_id
            })

    return result

@router.get("/doctor")
def get_doctor_avis(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()

    return db.query(Avis).filter(Avis.dermatologue_id == doctor.id).all()

