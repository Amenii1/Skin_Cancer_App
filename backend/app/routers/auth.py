from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.schemas.utilisateur import UserCreate, UserLogin
from pydantic import BaseModel
from app.services.auth_service import (
    register,
    login,
    request_password_reset,
    reset_password,
)
from app.core.dependencies import get_db

router = APIRouter(prefix="/auth", tags=["Auth"])


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


@router.post("/register")
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    return register(db, user)


@router.post("/login")
def login_user(user: UserLogin, db: Session = Depends(get_db)):
    return login(db, user.email, user.password)


@router.post("/forgot-password")
def forgot_password(
    payload: ForgotPasswordRequest, db: Session = Depends(get_db)
):
    return request_password_reset(db, payload.email)


@router.post("/reset-password")
def reset_password_route(
    payload: ResetPasswordRequest, db: Session = Depends(get_db)
):
    return reset_password(db, payload.email, payload.code, payload.new_password)
