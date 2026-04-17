from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.dermatologue import Dermatologue
from app.models.notification import Notification
from app.models.utilisateur import Utilisateur

router = APIRouter(prefix="/notifications", tags=["Notifications"])


def _serialize_notification(db: Session, n: Notification) -> dict:
    doctor_data = None
    if n.doctor_id:
        doctor = db.query(Dermatologue).filter(Dermatologue.id == n.doctor_id).first()
        if doctor:
            doctor_user = db.query(Utilisateur).filter(Utilisateur.id == doctor.user_id).first()
            doctor_data = {
                "id": doctor.id,
                "name": doctor_user.nom if doctor_user else None,
                "email": doctor_user.email if doctor_user else None,
                "phone": doctor_user.telephone if doctor_user else None,
                "specialite": doctor.specialite,
                "ville": doctor.ville,
                "adresse": doctor.adresse_cabinet,
            }

    return {
        "id": n.id,
        "title": n.title,
        "body": n.body,
        "kind": n.kind,
        "read": n.read,
        "image_id": n.image_id,
        "doctor": doctor_data,
        "created_at": n.created_at.isoformat() if n.created_at else None,
    }


@router.get("")
def list_notifications(
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(
            status_code=403,
            detail="Les notifications patient ne concernent que les comptes patient",
        )

    q = db.query(Notification).filter(Notification.user_id == current_user.id)
    if unread_only:
        q = q.filter(Notification.read.is_(False))
    rows = q.order_by(Notification.created_at.desc()).all()

    return {
        "notifications": [_serialize_notification(db, n) for n in rows]
    }


@router.patch("/{notification_id}/read")
def mark_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    n = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.user_id == current_user.id,
        )
        .first()
    )
    if not n:
        raise HTTPException(status_code=404, detail="Notification not found")
    n.read = True
    db.commit()
    return {"message": "ok", "id": notification_id}


@router.post("/read-all")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    rows = (
        db.query(Notification)
        .filter(
            Notification.user_id == current_user.id,
            Notification.read.is_(False),
        )
        .all()
    )
    for n in rows:
        n.read = True
    db.commit()
    return {"message": "ok", "marked": len(rows)}
