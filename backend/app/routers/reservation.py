from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.dependencies import get_db, get_current_user
from app.models.disponibilite import Disponibilite
from app.models.dermatologue import Dermatologue
from app.models.patient import Patient
from app.models.reservation import Reservation
from app.models.utilisateur import Utilisateur

router = APIRouter(prefix="/reservations", tags=["Reservations"])


def _serialize_reservation(db: Session, reservation: Reservation) -> dict:
    dispo = (
        db.query(Disponibilite)
        .filter(Disponibilite.id == reservation.disponibilite_id)
        .first()
    )
    patient = db.query(Patient).filter(Patient.id == reservation.patient_id).first()
    doctor = None
    doctor_user = None
    patient_user = None
    if dispo:
        doctor = (
            db.query(Dermatologue)
            .filter(Dermatologue.id == dispo.dermatologue_id)
            .first()
        )
    if doctor:
        doctor_user = db.query(Utilisateur).filter(Utilisateur.id == doctor.user_id).first()
    if patient:
        patient_user = db.query(Utilisateur).filter(Utilisateur.id == patient.user_id).first()

    return {
        "id": reservation.id,
        "patient_id": reservation.patient_id,
        "patient_name": patient_user.nom if patient_user else None,
        "patient_email": patient_user.email if patient_user else None,
        "disponibilite_id": reservation.disponibilite_id,
        "date_rdv": reservation.date_rdv.isoformat() if reservation.date_rdv else None,
        "status": reservation.status,
        "doctor_id": doctor.id if doctor else None,
        "doctor_name": doctor_user.nom if doctor_user else None,
        "doctor_email": doctor_user.email if doctor_user else None,
        "doctor_specialite": doctor.specialite if doctor else None,
        "doctor_adresse": doctor.adresse_cabinet if doctor else None,
        "doctor_ville": doctor.ville if doctor else None,
        "disponibilite_date": dispo.date.isoformat() if dispo and dispo.date else None,
        "heure_debut": dispo.heure_debut.isoformat() if dispo and dispo.heure_debut else None,
        "heure_fin": dispo.heure_fin.isoformat() if dispo and dispo.heure_fin else None,
    }

@router.post("/")
def create_reservation(
    disponibilite_id: Optional[int] = Query(default=None),
    payload: Optional[dict] = Body(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can reserve")

    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    dispo_id = disponibilite_id
    if dispo_id is None and payload:
        raw = payload.get("disponibilite_id")
        dispo_id = int(raw) if raw is not None else None
    if dispo_id is None:
        raise HTTPException(status_code=400, detail="disponibilite_id is required")

    dispo = db.query(Disponibilite).filter(Disponibilite.id == dispo_id).first()
    if not dispo:
        raise HTTPException(status_code=404, detail="Disponibilite not found")
    if dispo.is_reserved:
        raise HTTPException(status_code=400, detail="Disponibilite already reserved")

    new_reservation = Reservation(
        patient_id=patient.id,
        disponibilite_id=dispo_id,
        date_rdv=datetime.combine(dispo.date, dispo.heure_debut),
        status="pending",
    )
    dispo.is_reserved = True

    db.add(new_reservation)
    db.commit()
    db.refresh(new_reservation)

    return {
        "message": "Reservation created",
        "reservation_id": new_reservation.id,
        "reservation": _serialize_reservation(db, new_reservation),
    }


@router.get("/my")
def get_my_reservations(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):

    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients")

    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    reservations = (
        db.query(Reservation)
        .filter(Reservation.patient_id == patient.id)
        .order_by(Reservation.date_rdv.desc())
        .all()
    )

    return [_serialize_reservation(db, r) for r in reservations]


@router.get("/doctor")
def get_doctor_reservations(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = db.query(Dermatologue).filter(
        Dermatologue.user_id == current_user.id
    ).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    reservations = (
        db.query(Reservation)
        .join(Disponibilite)
        .filter(Disponibilite.dermatologue_id == doctor.id)
        .order_by(Reservation.date_rdv.desc())
        .all()
    )

    return [_serialize_reservation(db, r) for r in reservations]


@router.put("/{reservation_id}")
def update_reservation_status(
    reservation_id: int,
    status: Optional[str] = Query(default=None),
    payload: Optional[dict] = Body(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    reservation = db.query(Reservation).filter(
        Reservation.id == reservation_id
    ).first()

    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")

    new_status = status or (payload or {}).get("status")
    if new_status not in ["accepted", "refused"]:
        raise HTTPException(status_code=400, detail="Invalid status")

    reservation.status = new_status
    if new_status == "refused":
        dispo = (
            db.query(Disponibilite)
            .filter(Disponibilite.id == reservation.disponibilite_id)
            .first()
        )
        if dispo:
            dispo.is_reserved = False
    db.commit()

    return {
        "message": f"Reservation {new_status}",
        "reservation": _serialize_reservation(db, reservation),
    }