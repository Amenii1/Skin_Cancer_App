from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.dependencies import get_db
from app.models.image import Image
from app.services.notification_service import maybe_create_high_risk_notification
from app.services.ai_service import ai_service

router = APIRouter(prefix="/prediction", tags=["Prediction"])


@router.post("/{image_id}")
def predict(image_id: int, db: Session = Depends(get_db)):
    image = db.query(Image).filter(Image.id == image_id).first()

    if not image:
        raise HTTPException(status_code=404, detail="Image not found")

    is_loaded, model_error = ai_service.get_model_status()
    if not is_loaded:
        raise HTTPException(
            status_code=503,
            detail=f"AI model unavailable: {model_error}",
        )

    # Inférence réelle avec le modèle skin_cancer_model.h5
    try:
        result, confidence = ai_service.predict(image.path)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    # Sauvegarder les résultats
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