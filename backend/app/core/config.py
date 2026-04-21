import os
from pathlib import Path
from dotenv import load_dotenv

# Charger les variables d'environnement depuis .env
load_dotenv()

# ===============================
# DATABASE CONFIGURATION
# ===============================

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:asma2003@localhost:5432/skin_db"
)

# ===============================
# SECURITY CONFIGURATION
# ===============================

SECRET_KEY = os.getenv("SECRET_KEY", "mysecretkey123")

ALGORITHM = "HS256"

ACCESS_TOKEN_EXPIRE_MINUTES = 60

# ===============================
# APP CONFIGURATION
# ===============================

APP_NAME = "Skin Cancer Detection API"
DEBUG = True
BASE_DIR = Path(__file__).resolve().parents[2]
MODEL_PATH = os.getenv(
    "MODEL_PATH",
    str(BASE_DIR / "app" / "ml" / "skin_cancer_model.h5")
)

# ===============================
# RISK & NOTIFICATIONS (prédiction -> alerte visite spécialiste)
# ===============================

HIGH_RISK_MIN_CONFIDENCE = float(os.getenv("HIGH_RISK_MIN_CONFIDENCE", "0.65"))

# Libellés considérés comme bénins (normalisés en minuscules)
BENIGN_LABELS = frozenset(
    s.strip().lower()
    for s in os.getenv(
        "BENIGN_LABELS",
        "benign,nevus,nv,benign_keratosis,df,vasc_lesion",
    ).split(",")
    if s.strip()
)

# Rayon par défaut pour dermatologues proches (km)
NEARBY_DERMATOLOGUES_RADIUS_KM = float(os.getenv("NEARBY_DERMATOLOGUES_RADIUS_KM", "50"))
NEARBY_DERMATOLOGUES_LIMIT = int(os.getenv("NEARBY_DERMATOLOGUES_LIMIT", "15"))
