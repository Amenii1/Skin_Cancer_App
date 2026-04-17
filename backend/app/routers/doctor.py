from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user, get_db
from app.models.avis import Avis
from app.models.dermatologue import Dermatologue
from app.models.disponibilite import Disponibilite
from app.models.image import Image
from app.models.patient import Patient
from app.models.reservation import Reservation
from app.models.utilisateur import Utilisateur

router = APIRouter(prefix="/doctor", tags=["Doctor"])


def _get_doctor_profile(db: Session, user_id: int) -> Dermatologue:
    doctor = db.query(Dermatologue).filter(Dermatologue.user_id == user_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")
    return doctor


def _get_risk_from_images(images: list[Image]) -> tuple[str, str]:
    risk = "Faible"
    risk_color = "low"

    for img in images:
        result = (img.result or "").lower()
        if result == "melanoma":
            return "Élevé", "high"
        if "carcinoma" in result or "basal" in result:
            risk = "Modéré"
            risk_color = "medium"

    return risk, risk_color


def _doctor_has_patient_access(db: Session, doctor_id: int, patient: Patient) -> bool:
    accepted_reservation = (
        db.query(Reservation)
        .join(Disponibilite, Disponibilite.id == Reservation.disponibilite_id)
        .filter(
            Disponibilite.dermatologue_id == doctor_id,
            Reservation.patient_id == patient.id,
            Reservation.status == "accepted",
        )
        .first()
    )
    if accepted_reservation:
        return True

    doctor_avis = (
        db.query(Avis)
        .join(Image, Image.id == Avis.image_id)
        .filter(
            Avis.dermatologue_id == doctor_id,
            Image.user_id == patient.user_id,
        )
        .first()
    )
    return doctor_avis is not None


@router.get("/patients")
def get_doctor_patients(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = _get_doctor_profile(db, current_user.id)

    accepted_reservations = (
        db.query(Reservation, Disponibilite)
        .join(Disponibilite, Disponibilite.id == Reservation.disponibilite_id)
        .filter(
            Disponibilite.dermatologue_id == doctor.id,
            Reservation.status == "accepted",
        )
        .all()
    )

    patient_last_visit: dict[int, str | None] = {}
    patient_ids = set()
    for reservation, dispo in accepted_reservations:
        patient_ids.add(reservation.patient_id)
        patient_last_visit[reservation.patient_id] = (
            reservation.date_rdv.isoformat() if reservation.date_rdv else None
        )
        if reservation.date_rdv is None and dispo and dispo.date:
            patient_last_visit[reservation.patient_id] = dispo.date.isoformat()

    avis_patient_user_ids = (
        db.query(Image.user_id)
        .join(Avis, Avis.image_id == Image.id)
        .filter(Avis.dermatologue_id == doctor.id)
        .distinct()
        .all()
    )
    avis_user_ids = {row[0] for row in avis_patient_user_ids}

    patients = (
        db.query(Patient)
        .filter((Patient.id.in_(patient_ids)) | (Patient.user_id.in_(avis_user_ids)))
        .all()
    )

    out = []
    for patient in patients:
        user = db.query(Utilisateur).filter(Utilisateur.id == patient.user_id).first()
        images = (
            db.query(Image)
            .filter(Image.user_id == patient.user_id)
            .order_by(Image.created_at.desc())
            .all()
        )
        risk, risk_color = _get_risk_from_images(images)
        last_visit = patient_last_visit.get(patient.id)
        if not last_visit:
            last_visit = images[0].created_at.isoformat() if images else None

        out.append(
            {
                "id": patient.id,
                "name": user.nom if user else "Inconnu",
                "email": user.email if user else None,
                "phone": user.telephone if user else None,
                "ville": patient.ville,
                "lesion_count": len(images),
                "risk_level": risk,
                "risk_color": risk_color,
                "last_visit": last_visit,
                "date_naissance": patient.date_naissance.isoformat()
                if patient.date_naissance
                else None,
                "type_peau": patient.type_peau,
                "antecedents_familiaux": patient.antecedents_familiaux,
            }
        )

    out.sort(key=lambda item: ((item["last_visit"] or ""), item["name"]), reverse=True)
    return out


@router.get("/patients/{patient_id}")
def get_patient_detail(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = _get_doctor_profile(db, current_user.id)

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    if not _doctor_has_patient_access(db, doctor.id, patient):
        raise HTTPException(status_code=403, detail="You cannot access this patient")

    user = db.query(Utilisateur).filter(Utilisateur.id == patient.user_id).first()

    images = (
        db.query(Image)
        .filter(Image.user_id == patient.user_id)
        .order_by(Image.created_at.desc())
        .all()
    )
    image_ids = [img.id for img in images]
    image_by_id = {img.id: img for img in images}

    avis_rows = []
    if image_ids:
        avis_rows = (
            db.query(Avis)
            .filter(
                Avis.dermatologue_id == doctor.id,
                Avis.image_id.in_(image_ids),
            )
            .all()
        )

    accepted_reservations = (
        db.query(Reservation, Disponibilite)
        .join(Disponibilite, Disponibilite.id == Reservation.disponibilite_id)
        .filter(
            Disponibilite.dermatologue_id == doctor.id,
            Reservation.patient_id == patient.id,
            Reservation.status == "accepted",
        )
        .order_by(Reservation.date_rdv.desc())
        .all()
    )

    return {
        "id": patient.id,
        "name": user.nom if user else "Inconnu",
        "email": user.email if user else None,
        "phone": user.telephone if user else None,
        "ville": patient.ville,
        "date_naissance": patient.date_naissance.isoformat()
        if patient.date_naissance
        else None,
        "genre": getattr(patient, "genre", None),
        "type_peau": patient.type_peau,
        "antecedents_familiaux": patient.antecedents_familiaux,
        "medical_record": [
            {
                "id": img.id,
                "path": img.path,
                "result": img.result,
                "confidence": img.confidence,
                "created_at": img.created_at.isoformat() if img.created_at else None,
                "location": img.body_zone_label or img.body_zone_id,
                "observation_date": img.observation_date.isoformat()
                if img.observation_date
                else None,
            }
            for img in images
        ],
        "avis_history": [
            {
                "id": avis.id,
                "image_id": avis.image_id,
                "commentaire": avis.commentaire,
                "diagnostic": avis.diagnostic,
                "rating": avis.rating,
                "date": image_by_id.get(avis.image_id).created_at.isoformat()
                if image_by_id.get(avis.image_id)
                and image_by_id.get(avis.image_id).created_at
                else None,
                "prediction_at_time": image_by_id.get(avis.image_id).result
                if image_by_id.get(avis.image_id)
                else None,
            }
            for avis in avis_rows
        ],
        "appointments": [
            {
                "id": reservation.id,
                "date_rdv": reservation.date_rdv.isoformat()
                if reservation.date_rdv
                else None,
                "status": reservation.status,
                "heure_debut": dispo.heure_debut.isoformat() if dispo else None,
                "heure_fin": dispo.heure_fin.isoformat() if dispo else None,
            }
            for reservation, dispo in accepted_reservations
        ],
    }
