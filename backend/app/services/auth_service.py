from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.models.utilisateur import Utilisateur
from app.core.security import hash_password, verify_password, create_token

def register(db: Session, user):
    # ✅ check email
    existing = db.query(Utilisateur).filter(Utilisateur.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already exists")

    # ✅ password validation
    if len(user.password) < 6:
        raise HTTPException(status_code=400, detail="Password too short")

    new_user = Utilisateur(
        nom=user.nom,
        email=user.email,
        password_hash=hash_password(user.password),
        role=user.role
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # ✅ return safe data
    return {
        "id": new_user.id,
        "email": new_user.email,
        "role": new_user.role
    }


def login(db: Session, email, password):
    user = db.query(Utilisateur).filter(Utilisateur.email == email).first()

    if not user:
        raise HTTPException(status_code=401, detail="Invalid email")

    if not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid password")

    token = create_token({
        "sub": user.email,
        "role": user.role
    })

    return {
        "access_token": token,
        "token_type": "bearer"
    }