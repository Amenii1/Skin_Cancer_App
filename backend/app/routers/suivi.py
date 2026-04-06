import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import case

from app.core.dependencies import get_db, get_current_user
from app.models.image import Image

router = APIRouter(prefix="/suivi", tags=["Suivi"])


def _ordered_images(db: Session, user_id: int):
    return (
        db.query(Image)
        .filter(Image.user_id == user_id)
        .order_by(
            case((Image.observation_date.is_(None), 1), else_=0),
            Image.observation_date.desc(),
            Image.created_at.desc(),
        )
        .all()
    )


def _symptoms_for(img: Image) -> list[str]:
    if not img.symptoms_json:
        return []
    try:
        data = json.loads(img.symptoms_json)
    except json.JSONDecodeError:
        return []
    if not isinstance(data, list):
        return []
    return [str(item) for item in data if str(item).strip()]


@router.get("/timeline")
def timeline(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Suivi chronologique selon la date déclarée par le patient (observation_date)."""
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can view their timeline")

    imgs = _ordered_images(db, current_user.id)

    return {
        "points": [
            {
                "image_id": img.id,
                "observation_date": img.observation_date.isoformat()
                if img.observation_date
                else None,
                "uploaded_at": img.created_at.isoformat() if img.created_at else None,
                "result": img.result,
                "confidence": img.confidence,
                "body_zone_id": img.body_zone_id,
                "body_zone_label": img.body_zone_label,
                "symptoms": _symptoms_for(img),
            }
            for img in imgs
        ]
    }


@router.get("/compare")
def compare(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can compare their images")

    imgs = _ordered_images(db, current_user.id)

    if len(imgs) < 2:
        return {"msg": "not enough data", "need_at_least": 2}

    newest, previous = imgs[0], imgs[1]
    return {
        "newest": {
            "image_id": newest.id,
            "observation_date": newest.observation_date.isoformat()
            if newest.observation_date
            else None,
            "result": newest.result,
            "confidence": newest.confidence,
            "body_zone_label": newest.body_zone_label,
            "symptoms": _symptoms_for(newest),
        },
        "previous": {
            "image_id": previous.id,
            "observation_date": previous.observation_date.isoformat()
            if previous.observation_date
            else None,
            "result": previous.result,
            "confidence": previous.confidence,
            "body_zone_label": previous.body_zone_label,
            "symptoms": _symptoms_for(previous),
        },
    }
