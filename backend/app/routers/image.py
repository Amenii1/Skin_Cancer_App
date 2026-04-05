from datetime import datetime

from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException, Request
from sqlalchemy import case, or_
from sqlalchemy.orm import Session
import base64
import os
from uuid import uuid4

from app.core.dependencies import get_current_user, get_db
from app.models.image import Image
from app.models.utilisateur import Utilisateur
from app.models.dermatologue import Dermatologue
from app.models.avis import Avis

router = APIRouter(prefix="/image", tags=["Image"])

UPLOAD_DIR = "uploads"

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)


def _parse_observation_date(raw: str):
    try:
        return datetime.strptime(raw.strip(), "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="observation_date doit être au format YYYY-MM-DD",
        )


@router.post("/upload")
async def upload_image(
    request: Request,
    observation_date: str = Form(
        ...,
        description="Date déclarée par le patient (prise de vue / observation), format YYYY-MM-DD",
    ),
    file: UploadFile | None = File(None),
    base64_image: str | None = Form(None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can upload images")

    obs = _parse_observation_date(observation_date)

    filename = f"{uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_DIR, filename)

    if file:
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())
    elif base64_image:
        image_data = base64.b64decode(base64_image)
        with open(file_path, "wb") as f:
            f.write(image_data)
    else:
        raise HTTPException(status_code=400, detail="No image provided")

    new_image = Image(
        user_id=current_user.id,
        path=file_path,
        observation_date=obs,
    )

    db.add(new_image)
    db.commit()
    db.refresh(new_image)

    return {
        "message": "Image uploaded successfully",
        "image_id": new_image.id,
        "observation_date": obs.isoformat(),
        "path": file_path,
        "image_url": f"{request.base_url}uploads/{os.path.basename(file_path)}",
    }


@router.get("/list")
def list_my_images(
    request: Request,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can list their images")

    rows = (
        db.query(Image)
        .filter(Image.user_id == current_user.id)
        .order_by(
            case((Image.observation_date.is_(None), 1), else_=0),
            Image.observation_date.desc(),
            Image.created_at.desc(),
        )
        .all()
    )

    return {
        "images": [
            {
                "id": r.id,
                "observation_date": r.observation_date.isoformat()
                if r.observation_date
                else None,
                "created_at": r.created_at.isoformat() if r.created_at else None,
                "result": r.result,
                "confidence": r.confidence,
                "path": r.path,
                "image_url": f"{request.base_url}uploads/{os.path.basename(r.path)}",
            }
            for r in rows
        ]
    }


@router.get("/doctor/pending")
def list_pending_opinions_for_doctor(
    request: Request,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Images patients analysées (IA) sans avis du médecin connecté."""
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == current_user.id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    reviewed_ids = [
        row[0]
        for row in db.query(Avis.image_id)
        .filter(Avis.dermatologue_id == doctor.id)
        .all()
    ]

    q = (
        db.query(Image)
        .join(Utilisateur, Image.user_id == Utilisateur.id)
        .filter(Utilisateur.role == "patient")
        .filter(or_(Image.confidence.isnot(None), Image.result.isnot(None)))
    )
    if reviewed_ids:
        q = q.filter(~Image.id.in_(reviewed_ids))

    rows = q.order_by(Image.created_at.desc()).all()

    out = []
    for r in rows:
        user = db.query(Utilisateur).filter(Utilisateur.id == r.user_id).first()
        out.append(
            {
                "id": r.id,
                "patient_name": user.nom if user else None,
                "patient_email": user.email if user else None,
                "observation_date": r.observation_date.isoformat()
                if r.observation_date
                else None,
                "created_at": r.created_at.isoformat() if r.created_at else None,
                "result": r.result,
                "confidence": r.confidence,
                "path": r.path,
                "image_url": f"{request.base_url}uploads/{os.path.basename(r.path)}",
                "zone": r.result or "Lésion",
            }
        )
    return {"images": out}
