from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.schemas.utilisateur import UserCreate, UserLogin
from app.services.auth_service import register, login
from app.core.database import SessionLocal

router = APIRouter(prefix="/auth", tags=["Auth"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    return register(db, user)

@router.post("/login")
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    result = login(db, user.email, user.password)
    if not result:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return result

