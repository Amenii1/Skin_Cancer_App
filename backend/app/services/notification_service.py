from sqlalchemy.orm import Session

from app.models.dermatologue import Dermatologue
from app.models.image import Image
from app.models.notification import Notification
from app.models.patient import Patient
from app.models.reservation import Reservation
from app.models.utilisateur import Utilisateur
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

    title = "Consultation dermatologique recommandee"
    body = (
        "L'analyse automatique indique un resultat qui merite un avis specialise. "
        "Prenez rendez-vous avec un dermatologue proche de chez vous des que possible."
    )
    if result:
        body = f"Resultat : {result}. " + body

    notification = Notification(
        user_id=user_id,
        image_id=image_id,
        title=title,
        body=body,
        kind="high_risk_referral",
        read=False,
    )
    db.add(notification)
    return notification


def create_reservation_status_notification(
    db: Session,
    *,
    reservation: Reservation,
    doctor: Dermatologue,
    status: str,
) -> Notification | None:
    patient = db.query(Patient).filter(Patient.id == reservation.patient_id).first()
    if not patient:
        return None

    doctor_user = db.query(Utilisateur).filter(Utilisateur.id == doctor.user_id).first()
    doctor_name = doctor_user.nom if doctor_user else "Votre dermatologue"

    title = "Rendez-vous confirme" if status == "accepted" else "Rendez-vous refuse"
    body = (
        f"{doctor_name} a confirme votre rendez-vous."
        if status == "accepted"
        else f"{doctor_name} a refuse votre rendez-vous."
    )

    notification = Notification(
        user_id=patient.user_id,
        doctor_id=doctor.id,
        title=title,
        body=body,
        kind=f"reservation_{status}",
        read=False,
    )
    db.add(notification)
    return notification


def create_doctor_avis_notification(
    db: Session,
    *,
    image: Image,
    doctor: Dermatologue,
    is_update: bool,
) -> Notification:
    doctor_user = db.query(Utilisateur).filter(Utilisateur.id == doctor.user_id).first()
    doctor_name = doctor_user.nom if doctor_user else "Votre dermatologue"

    notification = Notification(
        user_id=image.user_id,
        image_id=image.id,
        doctor_id=doctor.id,
        title="Avis medical recu",
        body=(
            f"{doctor_name} a mis a jour son avis sur votre analyse."
            if is_update
            else f"{doctor_name} a donne un avis sur votre analyse."
        ),
        kind="doctor_avis",
        read=False,
    )
    db.add(notification)
    return notification
