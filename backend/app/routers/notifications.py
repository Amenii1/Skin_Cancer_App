from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.notification import Notification

router = APIRouter(prefix="/notifications", tags=["Notifications"])


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
        "notifications": [
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "kind": n.kind,
                "read": n.read,
                "image_id": n.image_id,
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
            for n in rows
        ]
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
