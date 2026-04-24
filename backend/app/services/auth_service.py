from datetime import date, datetime, timedelta
import random

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password, create_token
from app.models.utilisateur import Utilisateur
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue

SYSTEM_ADMIN_NAME = "admin"
SYSTEM_ADMIN_PASSWORD = "admin"
SYSTEM_ADMIN_EMAIL = "admin"


def ensure_system_admin(db: Session) -> Utilisateur:
    admin_user = (
        db.query(Utilisateur)
        .filter(Utilisateur.role == "admin")
        .order_by(Utilisateur.id.asc())
        .first()
    )

    if admin_user:
        if admin_user.nom != SYSTEM_ADMIN_NAME:
            admin_user.nom = SYSTEM_ADMIN_NAME
        if admin_user.email != SYSTEM_ADMIN_EMAIL:
            admin_user.email = SYSTEM_ADMIN_EMAIL
        if not getattr(admin_user, "is_active", True):
            admin_user.is_active = True
        if not verify_password(SYSTEM_ADMIN_PASSWORD, admin_user.password_hash):
            admin_user.password_hash = hash_password(SYSTEM_ADMIN_PASSWORD)
        db.commit()
        db.refresh(admin_user)
        return admin_user

    admin_user = Utilisateur(
        nom=SYSTEM_ADMIN_NAME,
        email=SYSTEM_ADMIN_EMAIL,
        password_hash=hash_password(SYSTEM_ADMIN_PASSWORD),
        role="admin",
        is_active=True,
        telephone=None,
    )
    db.add(admin_user)
    db.commit()
    db.refresh(admin_user)
    return admin_user


def register(db: Session, user):
    if user.role == "admin":
        raise HTTPException(
            status_code=403,
            detail="Admin account is managed by the system",
        )

    existing = db.query(Utilisateur).filter(Utilisateur.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already exists")
    if len(user.password) < 6:
        raise HTTPException(status_code=400, detail="Password too short")

    new_user = Utilisateur(
        nom=user.nom,
        email=user.email,
        password_hash=hash_password(user.password),
        role=user.role,
        is_active=True,
        telephone=user.telephone,
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if user.role == "patient":
        dob = None
        if user.date_naissance:
            try:
                dob = date.fromisoformat(user.date_naissance.strip())
            except ValueError:
                raise HTTPException(
                    status_code=400, detail="date_naissance must be YYYY-MM-DD"
                )
        patient = Patient(user_id=new_user.id, date_naissance=dob)
        db.add(patient)

    elif user.role == "doctor":
        doctor = Dermatologue(
            user_id=new_user.id,
            specialite=user.specialite,
            adresse_cabinet=user.adresse_cabinet,
            ville=user.ville,
            numero_rpps=user.numero_rpps,
        )
        db.add(doctor)

    db.commit()

    return {
        "id": new_user.id,
        "email": new_user.email,
        "role": new_user.role,
    }


def login(db: Session, email, password):
    ensure_system_admin(db)
    user = (
        db.query(Utilisateur)
        .filter((Utilisateur.email == email) | (Utilisateur.nom == email))
        .first()
    )

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email")

    if not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid password")

    token = create_token(
        {
            "sub": user.email,
            "role": user.role,
        }
    )

    return {
        "access_token": token,
        "token_type": "bearer",
    }


def request_password_reset(db: Session, email: str):
    user = db.query(Utilisateur).filter(Utilisateur.email == email).first()
    if not user:
        return {
            "message": "Si cet email existe, un code de reinitialisation a ete genere."
        }

    code = f"{random.randint(0, 999999):06d}"
    user.reset_code = code
    user.reset_code_expires_at = datetime.utcnow() + timedelta(minutes=15)
    db.commit()

    return {
        "message": "Code de reinitialisation genere.",
        "reset_code": code,  # dev-only until email sending is implemented
        "expires_in_minutes": 15,
    }


def reset_password(db: Session, email: str, code: str, new_password: str):
    user = db.query(Utilisateur).filter(Utilisateur.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if not user.reset_code or not user.reset_code_expires_at:
        raise HTTPException(status_code=400, detail="No reset request found")

    if datetime.utcnow() > user.reset_code_expires_at:
        raise HTTPException(status_code=400, detail="Reset code expired")

    if user.reset_code != code:
        raise HTTPException(status_code=400, detail="Invalid reset code")

    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password too short")

    user.password_hash = hash_password(new_password)
    user.reset_code = None
    user.reset_code_expires_at = None
    db.commit()

    return {"message": "Password reset successfully"}
