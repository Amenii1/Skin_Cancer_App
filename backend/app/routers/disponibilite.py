from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, get_current_user
from app.models.disponibilite import Disponibilite
from app.models.dermatologue import Dermatologue
from app.schemas.disponibilite import DisponibiliteCreate


router = APIRouter(prefix="/disponibilites", tags=["Disponibilites"])


# 👨‍⚕️ add dispo
@router.post("/")
def add_disponibilite(
    data: DisponibiliteCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):

    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctor allowed")

    doctor = db.query(Dermatologue).filter(
        Dermatologue.user_id == current_user.id
    ).first()

    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    dispo = Disponibilite(
        dermatologue_id=doctor.id,
        date=data.date,
        heure_debut=data.heure_debut,
        heure_fin=data.heure_fin
    )

    db.add(dispo)
    db.commit()
    db.refresh(dispo)

    return {"message": "Disponibilité ajoutée", "id": dispo.id}

# 👤 voir dispo
@router.get("/{doctor_id}")
def get_disponibilites(doctor_id: int, db: Session = Depends(get_db)):
    rows = db.query(Disponibilite).filter(
        Disponibilite.dermatologue_id == doctor_id,
        Disponibilite.is_reserved == False,
    ).all()
    return [
        {
            "id": d.id,
            "dermatologue_id": d.dermatologue_id,
            "date": d.date.isoformat() if d.date else None,
            "heure_debut": d.heure_debut.isoformat() if d.heure_debut else None,
            "heure_fin": d.heure_fin.isoformat() if d.heure_fin else None,
            "is_reserved": d.is_reserved,
            "start_iso": f"{d.date.isoformat()}T{d.heure_debut.isoformat()}"
            if d.date and d.heure_debut
            else None,
            "end_iso": f"{d.date.isoformat()}T{d.heure_fin.isoformat()}"
            if d.date and d.heure_fin
            else None,
        }
        for d in rows
    ]