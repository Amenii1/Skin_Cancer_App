from pydantic import BaseModel, EmailStr, field_validator

ALLOWED_ROLES = frozenset({"patient", "doctor"})


class UserCreate(BaseModel):
    nom: str
    email: EmailStr
    password: str
    role: str

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Password too short")
        return v

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in ALLOWED_ROLES:
            raise ValueError('role must be "patient" or "doctor"')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str