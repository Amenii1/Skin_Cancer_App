from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, get_current_user
from app.models.reservation import Reservation
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue
from app.schemas.reservation import ReservationCreate, ReservationUpdate
from app.models.disponibilite import Disponibilite

router = APIRouter(prefix="/reservations", tags=["Reservations"])

@router.post("/")
def create_reservation(
    disponibilite_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):

    # 🔒 seulement patient
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can reserve")

    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient profile not found")

    dispo = db.query(Disponibilite).filter(Disponibilite.id == disponibilite_id).first()
    if not dispo:
        raise HTTPException(status_code=404, detail="Disponibilite not found")

    new_reservation = Reservation(
        patient_id=patient.id,
        disponibilite_id=disponibilite_id,
        date_rdv=dispo.date,
        status="pending"
    )

    db.add(new_reservation)
    db.commit()
    db.refresh(new_reservation)

    return {
        "message": "Reservation created",
        "reservation_id": new_reservation.id
    }


@router.get("/my")
def get_my_reservations(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):

    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients")

    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()

    reservations = db.query(Reservation).filter(
        Reservation.patient_id == patient.id
    ).all()

    return reservations


@router.get("/doctor")
def get_doctor_reservations(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    doctor = db.query(Dermatologue).filter(
        Dermatologue.user_id == current_user.id
    ).first()

    reservations = db.query(Reservation).join(Disponibilite).filter(
        Disponibilite.dermatologue_id == doctor.id
    ).all()

    return reservations


@router.put("/{reservation_id}")
def update_reservation_status(
    reservation_id: int,
    status: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctors")

    reservation = db.query(Reservation).filter(
        Reservation.id == reservation_id
    ).first()

    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")

    if status not in ["accepted", "refused"]:
        raise HTTPException(status_code=400, detail="Invalid status")

    reservation.status = status
    db.commit()

    return {"message": f"Reservation {status}"}