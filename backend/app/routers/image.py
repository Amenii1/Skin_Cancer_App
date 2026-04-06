from datetime import datetime
import json

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

BODY_MAP_OPTIONS = [
    {"id": "head_front", "label": "Tête / visage", "view": "front"},
    {"id": "neck_front", "label": "Cou", "view": "front"},
    {"id": "chest_front", "label": "Poitrine", "view": "front"},
    {"id": "abdomen_front", "label": "Abdomen", "view": "front"},
    {"id": "left_arm_front", "label": "Bras gauche", "view": "front"},
    {"id": "right_arm_front", "label": "Bras droit", "view": "front"},
    {"id": "left_leg_front", "label": "Jambe gauche", "view": "front"},
    {"id": "right_leg_front", "label": "Jambe droite", "view": "front"},
    {"id": "head_back", "label": "Nuque", "view": "back"},
    {"id": "upper_back", "label": "Haut du dos", "view": "back"},
    {"id": "lower_back", "label": "Bas du dos", "view": "back"},
    {"id": "left_arm_back", "label": "Bras gauche (dos)", "view": "back"},
    {"id": "right_arm_back", "label": "Bras droit (dos)", "view": "back"},
    {"id": "gluteal", "label": "Région fessière", "view": "back"},
    {"id": "left_leg_back", "label": "Jambe gauche (dos)", "view": "back"},
    {"id": "right_leg_back", "label": "Jambe droite (dos)", "view": "back"},
]

SYMPTOM_OPTIONS = [
    "Aucun symptôme ressenti",
    "Changement récent de taille",
    "Changement de couleur",
    "Bords devenus irréguliers",
    "Asymétrie nouvelle",
    "Démangeaison",
    "Douleur ou sensibilité",
    "Saignement spontané",
    "Croûte persistante",
    "Ulcération",
]

BODY_ZONE_LOOKUP = {item["id"]: item for item in BODY_MAP_OPTIONS}


def _parse_observation_date(raw: str):
    try:
        return datetime.strptime(raw.strip(), "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail="observation_date doit être au format YYYY-MM-DD",
        )


def _parse_symptoms(raw: str | None) -> list[str]:
    if not raw:
        return []
    try:
        decoded = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="symptoms doit être un JSON valide") from exc

    if not isinstance(decoded, list):
        raise HTTPException(status_code=400, detail="symptoms doit être une liste JSON")

    cleaned: list[str] = []
    for item in decoded:
        value = str(item).strip()
        if value and value in SYMPTOM_OPTIONS and value not in cleaned:
            cleaned.append(value)
    return cleaned


def _get_symptoms(row: Image) -> list[str]:
    if not row.symptoms_json:
        return []
    try:
        data = json.loads(row.symptoms_json)
    except json.JSONDecodeError:
        return []
    if not isinstance(data, list):
        return []
    return [str(item) for item in data if str(item).strip()]


def _serialize_image_row(request: Request, row: Image) -> dict:
    return {
        "id": row.id,
        "observation_date": row.observation_date.isoformat() if row.observation_date else None,
        "created_at": row.created_at.isoformat() if row.created_at else None,
        "result": row.result,
        "confidence": row.confidence,
        "body_zone_id": row.body_zone_id,
        "body_zone_label": row.body_zone_label,
        "symptoms": _get_symptoms(row),
        "path": row.path,
        "image_url": f"{request.base_url}uploads/{os.path.basename(row.path)}",
    }


@router.get("/intake-options")
def intake_options():
    return {
        "body_map_options": BODY_MAP_OPTIONS,
        "symptom_options": SYMPTOM_OPTIONS,
    }


@router.post("/upload")
async def upload_image(
    request: Request,
    observation_date: str = Form(
        ...,
        description="Date déclarée par le patient (prise de vue / observation), format YYYY-MM-DD",
    ),
    body_zone_id: str = Form(...),
    symptoms: str | None = Form(None),
    file: UploadFile | None = File(None),
    base64_image: str | None = Form(None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can upload images")

    obs = _parse_observation_date(observation_date)
    zone = BODY_ZONE_LOOKUP.get(body_zone_id.strip())
    if not zone:
        raise HTTPException(status_code=400, detail="Zone corporelle invalide")
    selected_symptoms = _parse_symptoms(symptoms)

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
        body_zone_id=zone["id"],
        body_zone_label=zone["label"],
        symptoms_json=json.dumps(selected_symptoms, ensure_ascii=False),
    )

    db.add(new_image)
    db.commit()
    db.refresh(new_image)

    return {
        "message": "Image uploaded successfully",
        "image_id": new_image.id,
        "observation_date": obs.isoformat(),
        "body_zone_id": new_image.body_zone_id,
        "body_zone_label": new_image.body_zone_label,
        "symptoms": selected_symptoms,
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

    return {"images": [_serialize_image_row(request, row) for row in rows]}


@router.get("/medical-record")
def medical_record(
    request: Request,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can view their medical record")

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

    grouped_by_zone: dict[str, dict] = {}
    for row in rows:
        key = row.body_zone_id or "unknown"
        group = grouped_by_zone.setdefault(
            key,
            {
                "body_zone_id": key,
                "body_zone_label": row.body_zone_label or "Zone non précisée",
                "entries": [],
            },
        )
        group["entries"].append(_serialize_image_row(request, row))

    return {
        "patient": {
            "id": current_user.id,
            "nom": current_user.nom,
            "email": current_user.email,
        },
        "total_entries": len(rows),
        "zones": list(grouped_by_zone.values()),
        "entries": [_serialize_image_row(request, row) for row in rows],
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
                "symptoms": _get_symptoms(r),
                "zone": r.result or "Lésion",
            }
        )
    return {"images": out}
