from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import NEARBY_DERMATOLOGUES_LIMIT, NEARBY_DERMATOLOGUES_RADIUS_KM
from app.core.dependencies import get_current_user, get_db
from app.core.geo import haversine_km
from app.models.dermatologue import Dermatologue
from app.models.patient import Patient
from app.models.utilisateur import Utilisateur

router = APIRouter(prefix="/referral", tags=["Referral"])


@router.get("/nearby-dermatologues")
def nearby_dermatologues(
    radius_km: float | None = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """
    Adresses de dermatologues proches : par GPS (lat/lon patient + cabinet)
    ou à défaut par ville renseignée sur le profil patient / médecin.
    """
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Réservé aux patients")

    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Profil patient introuvable")

    rmax = radius_km if radius_km is not None else NEARBY_DERMATOLOGUES_RADIUS_KM

    doctors = db.query(Dermatologue).all()

    # 1) Géolocalisation
    if patient.latitude is not None and patient.longitude is not None:
        out = []
        for d in doctors:
            if d.latitude is None or d.longitude is None:
                continue
            dist = haversine_km(
                patient.latitude,
                patient.longitude,
                d.latitude,
                d.longitude,
            )
            if dist <= rmax:
                u = db.query(Utilisateur).filter(Utilisateur.id == d.user_id).first()
                out.append(
                    {
                        "dermatologue_id": d.id,
                        "nom": u.nom if u else None,
                        "email": u.email if u else None,
                        "specialite": d.specialite,
                        "adresse_cabinet": d.adresse_cabinet,
                        "ville": d.ville,
                        "distance_km": round(dist, 2),
                    }
                )
        out.sort(key=lambda x: x["distance_km"])
        return {
            "mode": "gps",
            "items": out[:NEARBY_DERMATOLOGUES_LIMIT],
        }

    # 2) Par ville
    if patient.ville and str(patient.ville).strip():
        pv = patient.ville.strip().lower()
        items = []
        for d in doctors:
            if not d.ville:
                continue
            if d.ville.strip().lower() == pv:
                u = db.query(Utilisateur).filter(Utilisateur.id == d.user_id).first()
                items.append(
                    {
                        "dermatologue_id": d.id,
                        "nom": u.nom if u else None,
                        "email": u.email if u else None,
                        "specialite": d.specialite,
                        "adresse_cabinet": d.adresse_cabinet,
                        "ville": d.ville,
                        "distance_km": None,
                    }
                )
        return {
            "mode": "ville",
            "hint": "Pour un tri par distance exacte, renseignez latitude/longitude dans le profil.",
            "items": items[:NEARBY_DERMATOLOGUES_LIMIT],
        }

    raise HTTPException(
        status_code=400,
        detail=(
            "Renseignez votre ville ou votre position (latitude/longitude) dans le profil "
            "pour afficher des dermatologues proches."
        ),
    )
