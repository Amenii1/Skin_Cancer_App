from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.services.risk_service import should_refer_to_specialist


def maybe_create_high_risk_notification(
    db: Session,
    *,
    user_id: int,
    image_id: int,
    result: str | None,
    confidence: float | None,
) -> Notification | None:
    if not should_refer_to_specialist(result, confidence):
        return None

    existing = (
        db.query(Notification)
        .filter(
            Notification.image_id == image_id,
            Notification.kind == "high_risk_referral",
        )
        .first()
    )
    if existing:
        return None

    title = "Consultation dermatologique recommandée"
    body = (
        "L’analyse automatique indique un résultat qui mérite un avis spécialisé. "
        "Prenez rendez-vous avec un dermatologue proche de chez vous dès que possible."
    )
    if result:
        body = (
            f"Résultat : {result}. "
            + body
        )

    n = Notification(
        user_id=user_id,
        image_id=image_id,
        title=title,
        body=body,
        kind="high_risk_referral",
        read=False,
    )
    db.add(n)
    return n
