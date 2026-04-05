from datetime import date

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password, create_token
from app.models.utilisateur import Utilisateur
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue


def register(db: Session, user):

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
    user = db.query(Utilisateur).filter(Utilisateur.email == email).first()

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
