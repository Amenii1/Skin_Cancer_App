import hashlib

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_db
from app.models.image import Image
from app.services.notification_service import maybe_create_high_risk_notification

router = APIRouter(prefix="/prediction", tags=["Prediction"])


def _simulate_model_output(image_id: int) -> tuple[str, float]:
    """
    Simulation déterministe (remplacer par l’inférence réelle du modèle).
    Produit un mélange de résultats pour tester alertes + suivi.
    """
    h = int(hashlib.md5(str(image_id).encode()).hexdigest(), 16)
    r = h % 100
    if r < 45:
        return "benign", 0.82 + (h % 15) / 100.0
    if r < 75:
        return "melanoma", 0.68 + (h % 25) / 100.0
    return "basal_cell_carcinoma", 0.66 + (h % 20) / 100.0


@router.post("/{image_id}")
def predict(image_id: int, db: Session = Depends(get_db)):
    image = db.query(Image).filter(Image.id == image_id).first()

    if not image:
        raise HTTPException(status_code=404, detail="Image not found")

    result, confidence = _simulate_model_output(image_id)

    image.result = result
    image.confidence = confidence

    maybe_create_high_risk_notification(
        db,
        user_id=image.user_id,
        image_id=image.id,
        result=result,
        confidence=confidence,
    )

    db.commit()

    return {
        "image_id": image_id,
        "result": result,
        "confidence": confidence,
        "body_zone_id": image.body_zone_id,
        "body_zone_label": image.body_zone_label,
        "observation_date": image.observation_date.isoformat()
        if image.observation_date
        else None,
    }
