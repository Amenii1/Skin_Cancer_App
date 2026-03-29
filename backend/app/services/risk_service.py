from app.core.config import BENIGN_LABELS, HIGH_RISK_MIN_CONFIDENCE


def _norm(s: str) -> str:
    return (s or "").strip().lower()


def should_refer_to_specialist(result: str | None, confidence: float | None) -> bool:
    """
    Consultation dermatologue recommandée si le libellé n’est pas bénin
    et que la confiance du modèle dépasse le seuil configuré.
    """
    if confidence is None:
        return False
    try:
        c = float(confidence)
    except (TypeError, ValueError):
        return False

    label = _norm(result or "")
    if not label:
        return False

    if label in BENIGN_LABELS:
        return False

    return c >= HIGH_RISK_MIN_CONFIDENCE
