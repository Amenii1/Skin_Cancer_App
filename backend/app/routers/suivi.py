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


def _serialize_tracking_point(img: Image) -> dict:
    return {
        "image_id": img.id,
        "observation_date": img.observation_date.isoformat() if img.observation_date else None,
        "uploaded_at": img.created_at.isoformat() if img.created_at else None,
        "result": img.result,
        "confidence": img.confidence,
        "body_zone_id": img.body_zone_id,
        "body_zone_label": img.body_zone_label,
        "symptoms": _symptoms_for(img),
    }


def _zone_key(img: Image) -> str:
    return img.body_zone_id or "unknown"


def _zone_label(img: Image) -> str:
    return img.body_zone_label or "Zone non précisée"


def _lesion_key(img: Image) -> str:
    if img.result and img.result.strip():
        return img.result.strip().lower()
    return "unknown"


def _group_images_by_zone(imgs: list[Image]) -> list[dict]:
    grouped: dict[str, dict] = {}

    for img in imgs:
        key = _zone_key(img)
        group = grouped.setdefault(
            key,
            {
                "body_zone_id": key,
                "body_zone_label": _zone_label(img),
                "images": [],
            },
        )
        group["images"].append(img)

    zones: list[dict] = []
    for group in grouped.values():
        zone_images = group["images"]
        lesion_groups: dict[str, dict] = {}
        for img in zone_images:
            lesion_id = _lesion_key(img)
            lesion_group = lesion_groups.setdefault(
                lesion_id,
                {
                    "lesion_key": lesion_id,
                    "lesion_label": img.result or "Lésion non classée",
                    "points": [],
                },
            )
            lesion_group["points"].append(_serialize_tracking_point(img))

        zones.append(
            {
                "body_zone_id": group["body_zone_id"],
                "body_zone_label": group["body_zone_label"],
                "entry_count": len(zone_images),
                "latest_result": zone_images[0].result,
                "comparisons_available": len(zone_images) >= 2,
                "points": [_serialize_tracking_point(img) for img in zone_images],
                "lesion_groups": list(lesion_groups.values()),
            }
        )

    return zones


def _comparison_for_zone(zone_images: list[Image]) -> tuple[Image, Image, str] | None:
    if len(zone_images) < 2:
        return None

    newest = zone_images[0]
    newest_lesion_key = _lesion_key(newest)

    same_lesion_previous = next(
        (img for img in zone_images[1:] if _lesion_key(img) == newest_lesion_key),
        None,
    )
    if same_lesion_previous:
        return newest, same_lesion_previous, "same_lesion"

    return newest, zone_images[1], "same_zone"


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
        "points": [_serialize_tracking_point(img) for img in imgs],
        "zones": _group_images_by_zone(imgs),
        "total_points": len(imgs),
    }


@router.get("/compare")
def compare(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can compare their images")

    imgs = _ordered_images(db, current_user.id)

    zones = _group_images_by_zone(imgs)
    selected_zone = next((zone for zone in zones if zone["entry_count"] >= 2), None)

    if not selected_zone:
        return {
            "msg": "not enough data in the same zone",
            "need_at_least": 2,
            "same_zone_required": True,
            "zones": zones,
        }

    zone_images = [img for img in imgs if _zone_key(img) == selected_zone["body_zone_id"]]
    comparison = _comparison_for_zone(zone_images)
    if comparison is None:
        return {
            "msg": "not enough data in the same zone",
            "need_at_least": 2,
            "same_zone_required": True,
            "zones": zones,
        }

    newest, previous, comparison_basis = comparison
    return {
        "comparison_basis": comparison_basis,
        "body_zone_id": selected_zone["body_zone_id"],
        "body_zone_label": selected_zone["body_zone_label"],
        "newest": {
            "image_id": newest.id,
            "observation_date": newest.observation_date.isoformat()
            if newest.observation_date
            else None,
            "result": newest.result,
            "confidence": newest.confidence,
            "body_zone_id": newest.body_zone_id,
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
            "body_zone_id": previous.body_zone_id,
            "body_zone_label": previous.body_zone_label,
            "symptoms": _symptoms_for(previous),
        },
        "zones": zones,
    }
