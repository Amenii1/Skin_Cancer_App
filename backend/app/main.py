from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.database import Base, engine, SessionLocal
from app.core.sqlite_migrate import run_sqlite_migrations
from app.services.auth_service import ensure_system_admin

from app.models.utilisateur import Utilisateur  # noqa: F401
from app.models.patient import Patient  # noqa: F401
from app.models.dermatologue import Dermatologue  # noqa: F401
from app.models.image import Image  # noqa: F401
from app.models.avis import Avis  # noqa: F401
from app.models.notification import Notification  # noqa: F401

from app.routers import (
    admin,
    auth,
    user,
    profile,
    image,
    avis,
    suivi,
    prediction,
    notifications,
    referral,
    reservation,
    disponibilite,
    stats,
    doctor,
)

app = FastAPI(title="Skin Cancer API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    # Flutter web (localhost:PORT) + API (127.0.0.1:8000) : origines différentes ; regex renforce le dev local.
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

run_sqlite_migrations()
Base.metadata.create_all(bind=engine)  # Commented temporarily due to DB connection error

with SessionLocal() as db:
    ensure_system_admin(db)

app.include_router(admin.router)
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(profile.router)
app.include_router(image.router)
app.include_router(avis.router)
app.include_router(suivi.router)
app.include_router(prediction.router)
app.include_router(notifications.router)
app.include_router(referral.router)
app.include_router(reservation.router)
app.include_router(disponibilite.router)
app.include_router(stats.router)
app.include_router(doctor.router)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.get("/")
def home():
    return {"message": "API working 🚀"}
