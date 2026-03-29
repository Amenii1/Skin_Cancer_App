from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.utilisateur import UserCreate, UserLogin
from app.services.auth_service import register, login
from app.core.dependencies import get_db

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    return register(db, user)


@router.post("/login")
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    return login(db, user.email, user.password)
