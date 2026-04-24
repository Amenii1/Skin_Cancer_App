from datetime import date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, require_admin
from app.models.avis import Avis
from app.models.dermatologue import Dermatologue
from app.models.disponibilite import Disponibilite
from app.models.image import Image
from app.models.notification import Notification
from app.models.patient import Patient
from app.models.reservation import Reservation
from app.models.utilisateur import Utilisateur

router = APIRouter(prefix="/admin", tags=["Admin"])


def _iso(value):
    return value.isoformat() if value else None


def _is_suspicious_result(result: str | None) -> bool:
    if not result:
        return False
    text = result.strip().lower()
    return text == "melanoma" or "carcinoma" in text or "malignant" in text


def _is_benign_result(result: str | None) -> bool:
    if not result:
        return False
    text = result.strip().lower()
    return "benign" in text or text == "non-cancer" or text == "non cancer"


def _serialize_user(db: Session, user: Utilisateur) -> dict:
    patient = None
    doctor = None
    extra = {}

    if user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == user.id).first()
        if patient:
            analyses_count = db.query(Image).filter(Image.user_id == user.id).count()
            upcoming_count = (
                db.query(Reservation)
                .filter(Reservation.patient_id == patient.id)
                .count()
            )
            extra = {
                "patient_id": patient.id,
                "city": patient.ville,
                "date_naissance": _iso(patient.date_naissance),
                "analyses_count": analyses_count,
                "appointments_count": upcoming_count,
            }
    elif user.role == "doctor":
        doctor = db.query(Dermatologue).filter(Dermatologue.user_id == user.id).first()
        if doctor:
            reviews_count = db.query(Avis).filter(Avis.dermatologue_id == doctor.id).count()
            availability_count = (
                db.query(Disponibilite)
                .filter(Disponibilite.dermatologue_id == doctor.id)
                .count()
            )
            extra = {
                "doctor_id": doctor.id,
                "specialite": doctor.specialite,
                "city": doctor.ville,
                "reviews_count": reviews_count,
                "availability_count": availability_count,
            }

    return {
        "id": user.id,
        "name": user.nom,
        "email": user.email,
        "role": user.role,
        "telephone": user.telephone,
        "is_active": getattr(user, "is_active", True),
        **extra,
    }


def _serialize_dermatologist(db: Session, doctor: Dermatologue) -> dict:
    user = db.query(Utilisateur).filter(Utilisateur.id == doctor.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Doctor user not found")

    availabilities = (
        db.query(Disponibilite)
        .filter(Disponibilite.dermatologue_id == doctor.id)
        .order_by(Disponibilite.date.asc(), Disponibilite.heure_debut.asc())
        .all()
    )
    reservations = (
        db.query(Reservation)
        .join(Disponibilite, Disponibilite.id == Reservation.disponibilite_id)
        .filter(Disponibilite.dermatologue_id == doctor.id)
        .all()
    )
    reviews = db.query(Avis).filter(Avis.dermatologue_id == doctor.id).all()

    rating_values = [review.rating for review in reviews if review.rating is not None]
    average_rating = (
        round(sum(rating_values) / len(rating_values), 2) if rating_values else None
    )

    latest_activity = max(
        (
            reservation.date_rdv
            for reservation in reservations
            if reservation.date_rdv is not None
        ),
        default=None,
    )

    return {
        "id": doctor.id,
        "user_id": user.id,
        "name": user.nom,
        "email": user.email,
        "telephone": user.telephone,
        "is_active": getattr(user, "is_active", True),
        "specialite": doctor.specialite,
        "adresse_cabinet": doctor.adresse_cabinet,
        "ville": doctor.ville,
        "numero_rpps": doctor.numero_rpps,
        "average_rating": average_rating,
        "reviews_count": len(reviews),
        "appointments_count": len(reservations),
        "availability_count": len(availabilities),
        "latest_activity_at": latest_activity.isoformat()
        if latest_activity is not None
        else None,
        "availability": [
            {
                "id": slot.id,
                "date": _iso(slot.date),
                "heure_debut": _iso(slot.heure_debut),
                "heure_fin": _iso(slot.heure_fin),
                "is_reserved": slot.is_reserved,
            }
            for slot in availabilities[:8]
        ],
        "reviews": [
            {
                "id": review.id,
                "diagnostic": review.diagnostic,
                "commentaire": review.commentaire,
                "rating": review.rating,
            }
            for review in reviews[:5]
        ],
    }


def _serialize_appointment(db: Session, reservation: Reservation) -> dict:
    patient = db.query(Patient).filter(Patient.id == reservation.patient_id).first()
    dispo = (
        db.query(Disponibilite)
        .filter(Disponibilite.id == reservation.disponibilite_id)
        .first()
    )
    doctor = None
    patient_user = None
    doctor_user = None

    if patient:
        patient_user = db.query(Utilisateur).filter(Utilisateur.id == patient.user_id).first()
    if dispo:
        doctor = (
            db.query(Dermatologue)
            .filter(Dermatologue.id == dispo.dermatologue_id)
            .first()
        )
    if doctor:
        doctor_user = db.query(Utilisateur).filter(Utilisateur.id == doctor.user_id).first()

    return {
        "id": reservation.id,
        "status": reservation.status,
        "date_rdv": _iso(reservation.date_rdv),
        "patient_id": patient.id if patient else None,
        "patient_name": patient_user.nom if patient_user else None,
        "doctor_id": doctor.id if doctor else None,
        "doctor_name": doctor_user.nom if doctor_user else None,
        "doctor_specialite": doctor.specialite if doctor else None,
        "disponibilite_date": _iso(dispo.date) if dispo else None,
        "heure_debut": _iso(dispo.heure_debut) if dispo else None,
        "heure_fin": _iso(dispo.heure_fin) if dispo else None,
    }


def _serialize_analysis(db: Session, image: Image) -> dict:
    user = db.query(Utilisateur).filter(Utilisateur.id == image.user_id).first()
    patient = None
    if user:
        patient = db.query(Patient).filter(Patient.user_id == user.id).first()

    review_count = db.query(Avis).filter(Avis.image_id == image.id).count()
    prediction_label = "malignant" if _is_suspicious_result(image.result) else "benign"
    if not image.result:
        prediction_label = "unknown"

    return {
        "id": image.id,
        "patient_id": patient.id if patient else None,
        "patient_name": user.nom if user else None,
        "patient_email": user.email if user else None,
        "prediction": prediction_label,
        "result": image.result,
        "confidence": image.confidence,
        "body_zone_label": image.body_zone_label,
        "observation_date": _iso(image.observation_date),
        "created_at": _iso(image.created_at),
        "reviews_count": review_count,
        "image_path": image.path,
        "is_suspicious": _is_suspicious_result(image.result),
    }


def _build_usage_series(db: Session, days: int = 7) -> list[dict]:
    today = date.today()
    series = []
    for offset in range(days - 1, -1, -1):
        current_day = today - timedelta(days=offset)
        next_day = current_day + timedelta(days=1)
        start_dt = datetime.combine(current_day, datetime.min.time())
        end_dt = datetime.combine(next_day, datetime.min.time())
        count = (
            db.query(Image)
            .filter(Image.created_at >= start_dt, Image.created_at < end_dt)
            .count()
        )
        series.append({"date": current_day.isoformat(), "count": count})
    return series


def _delete_notifications_for_targets(
    db: Session,
    *,
    user_id: int | None = None,
    image_ids: list[int] | None = None,
    doctor_id: int | None = None,
) -> None:
    filters = []
    if user_id is not None:
        filters.append(Notification.user_id == user_id)
    if image_ids:
        filters.append(Notification.image_id.in_(image_ids))
    if doctor_id is not None:
        filters.append(Notification.doctor_id == doctor_id)

    if not filters:
        return

    notifications = db.query(Notification).filter(or_(*filters)).all()
    for notification in notifications:
        db.delete(notification)


@router.get("/overview")
def get_admin_overview(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    total_patients = db.query(Utilisateur).filter(Utilisateur.role == "patient").count()
    total_dermatologists = (
        db.query(Utilisateur).filter(Utilisateur.role == "doctor").count()
    )
    total_analyses = db.query(Image).count()
    total_appointments = db.query(Reservation).count()

    analyses = db.query(Image).all()
    cancer_cases = sum(1 for item in analyses if _is_suspicious_result(item.result))
    non_cancer_cases = sum(
        1
        for item in analyses
        if item.result
        and (_is_benign_result(item.result) or not _is_suspicious_result(item.result))
    )

    suspicious_analyses = [
        _serialize_analysis(db, image)
        for image in (
            db.query(Image).order_by(Image.created_at.desc()).limit(20).all()
        )
        if _is_suspicious_result(image.result)
    ][:5]

    recent_events = [
        {
            "id": notification.id,
            "title": notification.title,
            "body": notification.body,
            "kind": notification.kind,
            "created_at": _iso(notification.created_at),
        }
        for notification in (
            db.query(Notification)
            .order_by(Notification.created_at.desc())
            .limit(6)
            .all()
        )
    ]

    return {
        "stats": {
            "patients": total_patients,
            "dermatologists": total_dermatologists,
            "analyses": total_analyses,
            "appointments": total_appointments,
        },
        "case_distribution": {
            "cancer": cancer_cases,
            "non_cancer": non_cancer_cases,
        },
        "usage_over_time": _build_usage_series(db, days=7),
        "suspicious_cases": suspicious_analyses,
        "recent_events": recent_events,
    }


@router.get("/users")
def list_users(
    search: str | None = Query(default=None),
    role: str | None = Query(default=None),
    active: bool | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    query = db.query(Utilisateur)
    if role in {"patient", "doctor", "admin"}:
        query = query.filter(Utilisateur.role == role)
    if active is not None:
        query = query.filter(Utilisateur.is_active.is_(active))
    if search:
        pattern = f"%{search.strip()}%"
        query = query.filter(
            or_(Utilisateur.nom.ilike(pattern), Utilisateur.email.ilike(pattern))
        )

    rows = query.order_by(Utilisateur.id.desc()).all()
    return {"users": [_serialize_user(db, user) for user in rows]}


@router.get("/users/{user_id}")
def get_user_detail(
    user_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    user = db.query(Utilisateur).filter(Utilisateur.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    payload = _serialize_user(db, user)
    if user.role == "patient":
        images = (
            db.query(Image)
            .filter(Image.user_id == user.id)
            .order_by(Image.created_at.desc())
            .limit(10)
            .all()
        )
        payload["recent_analyses"] = [_serialize_analysis(db, image) for image in images]
    return payload


@router.patch("/users/{user_id}/status")
def set_user_status(
    user_id: int,
    payload: dict,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    user = db.query(Utilisateur).filter(Utilisateur.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Admin cannot deactivate self")

    is_active = payload.get("is_active")
    if not isinstance(is_active, bool):
        raise HTTPException(status_code=400, detail="is_active must be boolean")

    user.is_active = is_active
    db.commit()
    return {"message": "User status updated", "user": _serialize_user(db, user)}


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    user = db.query(Utilisateur).filter(Utilisateur.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.role == "admin":
        raise HTTPException(status_code=400, detail="System admin cannot be deleted")
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Admin cannot delete self")

    if user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == user.id).first()
        if patient:
            patient_images = db.query(Image).filter(Image.user_id == user.id).all()
            image_ids = [image.id for image in patient_images]
            _delete_notifications_for_targets(db, user_id=user.id, image_ids=image_ids)
            for image in patient_images:
                image_reviews = db.query(Avis).filter(Avis.image_id == image.id).all()
                for review in image_reviews:
                    db.delete(review)
                db.delete(image)
            reservations = db.query(Reservation).filter(Reservation.patient_id == patient.id).all()
            for reservation in reservations:
                dispo = (
                    db.query(Disponibilite)
                    .filter(Disponibilite.id == reservation.disponibilite_id)
                    .first()
                )
                if dispo:
                    dispo.is_reserved = False
                db.delete(reservation)
            db.delete(patient)
        else:
            _delete_notifications_for_targets(db, user_id=user.id)
    elif user.role == "doctor":
        doctor = db.query(Dermatologue).filter(Dermatologue.user_id == user.id).first()
        if doctor:
            doctor_image_ids = [
                image_id
                for (image_id,) in db.query(Avis.image_id)
                .filter(Avis.dermatologue_id == doctor.id)
                .all()
            ]
            _delete_notifications_for_targets(
                db,
                user_id=user.id,
                image_ids=doctor_image_ids,
                doctor_id=doctor.id,
            )
            slots = db.query(Disponibilite).filter(Disponibilite.dermatologue_id == doctor.id).all()
            for slot in slots:
                reservations = (
                    db.query(Reservation)
                    .filter(Reservation.disponibilite_id == slot.id)
                    .all()
                )
                for reservation in reservations:
                    db.delete(reservation)
                db.delete(slot)
            doctor_reviews = db.query(Avis).filter(Avis.dermatologue_id == doctor.id).all()
            for review in doctor_reviews:
                db.delete(review)
            db.delete(doctor)
        else:
            _delete_notifications_for_targets(db, user_id=user.id)
    else:
        _delete_notifications_for_targets(db, user_id=user.id)

    db.delete(user)
    db.commit()
    return {"message": "User deleted"}


@router.get("/dermatologists")
def list_dermatologists(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user
    doctors = db.query(Dermatologue).order_by(Dermatologue.id.desc()).all()
    return {"dermatologists": [_serialize_dermatologist(db, doctor) for doctor in doctors]}


@router.get("/appointments")
def list_appointments(
    appointment_date: str | None = Query(default=None),
    patient: str | None = Query(default=None),
    dermatologist: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    rows = db.query(Reservation).order_by(Reservation.date_rdv.desc()).all()
    items = [_serialize_appointment(db, reservation) for reservation in rows]

    if appointment_date:
        items = [
            item for item in items if (item["disponibilite_date"] or "").startswith(appointment_date)
        ]
    if patient:
        patient_lc = patient.lower()
        items = [
            item
            for item in items
            if patient_lc in (item["patient_name"] or "").lower()
        ]
    if dermatologist:
        doctor_lc = dermatologist.lower()
        items = [
            item
            for item in items
            if doctor_lc in (item["doctor_name"] or "").lower()
        ]

    return {"appointments": items}


@router.delete("/appointments/{appointment_id}")
def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    reservation = db.query(Reservation).filter(Reservation.id == appointment_id).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Appointment not found")

    dispo = (
        db.query(Disponibilite)
        .filter(Disponibilite.id == reservation.disponibilite_id)
        .first()
    )
    if dispo:
        dispo.is_reserved = False

    db.delete(reservation)
    db.commit()
    return {"message": "Appointment deleted"}


@router.get("/analyses")
def list_analyses(
    prediction: str | None = Query(default=None),
    patient: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    rows = db.query(Image).order_by(Image.created_at.desc()).all()
    items = [_serialize_analysis(db, image) for image in rows]

    if prediction in {"benign", "malignant", "unknown"}:
        items = [item for item in items if item["prediction"] == prediction]
    if patient:
        patient_lc = patient.lower()
        items = [
            item
            for item in items
            if patient_lc in (item["patient_name"] or "").lower()
        ]

    return {"analyses": items}


@router.get("/analyses/{analysis_id}")
def get_analysis_detail(
    analysis_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user
    image = db.query(Image).filter(Image.id == analysis_id).first()
    if not image:
        raise HTTPException(status_code=404, detail="Analysis not found")
    payload = _serialize_analysis(db, image)
    payload["reviews"] = [
        {
            "id": review.id,
            "diagnostic": review.diagnostic,
            "commentaire": review.commentaire,
            "rating": review.rating,
        }
        for review in db.query(Avis).filter(Avis.image_id == image.id).all()
    ]
    return payload


@router.get("/alerts")
def get_alerts(
    db: Session = Depends(get_db),
    current_user=Depends(require_admin),
):
    del current_user

    suspicious = [
        _serialize_analysis(db, image)
        for image in db.query(Image).order_by(Image.created_at.desc()).limit(25).all()
        if _is_suspicious_result(image.result)
    ]

    recent_events = [
        {
            "id": notification.id,
            "title": notification.title,
            "body": notification.body,
            "kind": notification.kind,
            "created_at": _iso(notification.created_at),
        }
        for notification in (
            db.query(Notification)
            .order_by(Notification.created_at.desc())
            .limit(10)
            .all()
        )
    ]

    return {
        "suspicious_cases": suspicious,
        "events": recent_events,
        "generated_at": datetime.utcnow().isoformat(),
    }
