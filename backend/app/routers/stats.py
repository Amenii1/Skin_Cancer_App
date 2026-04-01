from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import case
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.avis import Avis
from app.models.disponibilite import Disponibilite
from app.models.dermatologue import Dermatologue
from app.models.image import Image
from app.models.notification import Notification
from app.models.patient import Patient
from app.models.reservation import Reservation

router = APIRouter(prefix="/stats", tags=["Stats"])


def _risk_from_result(result: str | None) -> str:
    if not result:
        return "low"
    r = result.strip().lower()
    if r == "melanoma":
        return "high"
    if "basal" in r or "carcinoma" in r:
        return "medium"
    return "low"


def _global_risk_from_images(images: list[Image]) -> str:
    g = "low"
    for img in images:
        rk = _risk_from_result(img.result)
        if rk == "high":
            return "high"
        if rk == "medium":
            g = "medium"
    return g


@router.get("/dashboard")
def dashboard_stats(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Statistiques pour le tableau de bord — un seul appel authentifié, selon le rôle."""
    role = current_user.role

    if role == "patient":
        images = (
            db.query(Image)
            .filter(Image.user_id == current_user.id)
            .order_by(
                case((Image.observation_date.is_(None), 1), else_=0),
                Image.observation_date.desc(),
                Image.created_at.desc(),
            )
            .all()
        )

        total = len(images)
        days_since = None
        if images:
            first = images[0]
            od = first.observation_date
            if od:
                days_since = (date.today() - od).days
            elif first.created_at:
                ca = first.created_at
                if ca.tzinfo is None:
                    ca = ca.replace(tzinfo=timezone.utc)
                days_since = (datetime.now(timezone.utc) - ca).days

        unread = (
            db.query(Notification)
            .filter(
                Notification.user_id == current_user.id,
                Notification.read.is_(False),
            )
            .count()
        )

        preview = images[:3]
        recent = [
            {
                "id": img.id,
                "observation_date": img.observation_date.isoformat()
                if img.observation_date
                else None,
                "created_at": img.created_at.isoformat() if img.created_at else None,
                "result": img.result,
                "confidence": img.confidence,
            }
            for img in preview
        ]

        notif_rows = (
            db.query(Notification)
            .filter(Notification.user_id == current_user.id)
            .order_by(Notification.created_at.desc())
            .limit(5)
            .all()
        )
        notifications_preview = [
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "kind": n.kind,
                "read": n.read,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
            for n in notif_rows
        ]

        return {
            "role": "patient",
            "nom": current_user.nom,
            "email": current_user.email,
            "total_lesions": total,
            "global_risk": _global_risk_from_images(images),
            "days_since_last_scan": days_since,
            "unread_notifications": unread,
            "recent_images": recent,
            "notifications_preview": notifications_preview,
        }

    if role == "doctor":
        doctor = (
            db.query(Dermatologue)
            .filter(Dermatologue.user_id == current_user.id)
            .first()
        )
        if not doctor:
            return {
                "role": "doctor",
                "nom": current_user.nom,
                "email": current_user.email,
                "pending_reservations": 0,
                "total_reservations": 0,
                "total_avis": 0,
                "warning": "Profil médecin introuvable",
            }

        total_res = (
            db.query(Reservation)
            .join(Disponibilite)
            .filter(Disponibilite.dermatologue_id == doctor.id)
            .count()
        )
        pending_res = (
            db.query(Reservation)
            .join(Disponibilite)
            .filter(
                Disponibilite.dermatologue_id == doctor.id,
                Reservation.status == "pending",
            )
            .count()
        )
        total_avis = (
            db.query(Avis).filter(Avis.dermatologue_id == doctor.id).count()
        )

        return {
            "role": "doctor",
            "nom": current_user.nom,
            "email": current_user.email,
            "pending_reservations": pending_res,
            "total_reservations": total_res,
            "total_avis": total_avis,
        }

    return {
        "role": role,
        "nom": current_user.nom,
        "email": current_user.email,
        "message": "Rôle non pris en charge pour les stats",
    }
