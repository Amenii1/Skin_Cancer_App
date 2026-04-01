from fastapi import APIRouter, Depends, HTTPException, Query
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
    lat: float | None = Query(default=None),
    lng: float | None = Query(default=None),
    radius_km: float | None = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Patients only")

    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    effective_lat = lat
    effective_lng = lng
    source = "query_gps"
    if effective_lat is None or effective_lng is None:
        if patient and patient.latitude is not None and patient.longitude is not None:
            effective_lat = patient.latitude
            effective_lng = patient.longitude
            source = "patient_profile"
        else:
            source = "global"

    rmax = radius_km if radius_km else NEARBY_DERMATOLOGUES_RADIUS_KM

    doctors = db.query(Dermatologue).all()
    result = []
    global_items = []

    for d in doctors:
        user = db.query(Utilisateur).filter(Utilisateur.id == d.user_id).first()
        ratings = [a.rating for a in d.avis if hasattr(a, "rating")]
        avg_rating = sum(ratings) / len(ratings) if ratings else 0

        base_item = {
            "dermatologue_id": d.id,
            "nom": user.nom if user else "",
            "email": user.email if user else "",
            "specialite": d.specialite,
            "adresse_cabinet": d.adresse_cabinet,
            "ville": d.ville,
            "latitude": d.latitude,
            "longitude": d.longitude,
            "distance_km": None,
            "rating": round(avg_rating, 1),
            "available": True,
            "phone": None,
        }

        global_items.append(base_item)

        if (
            effective_lat is not None
            and effective_lng is not None
            and d.latitude is not None
            and d.longitude is not None
        ):
            dist = haversine_km(effective_lat, effective_lng, d.latitude, d.longitude)
            if dist <= rmax:
                item = dict(base_item)
                item["distance_km"] = round(dist, 2)
                result.append(item)

    if source == "global":
        global_items.sort(key=lambda x: (-x["rating"], x["nom"]))
        return {
            "mode": "global",
            "count": len(global_items),
            "items": global_items[:NEARBY_DERMATOLOGUES_LIMIT],
            "hint": "Activez la localisation pour des recommandations par distance.",
        }

    result.sort(key=lambda x: (x["distance_km"], -x["rating"]))

    return {
        "mode": "gps_realtime",
        "source": source,
        "count": len(result),
        "items": result[:NEARBY_DERMATOLOGUES_LIMIT],
    }
