from pydantic import BaseModel, EmailStr, field_validator

class UserCreate(BaseModel):
    nom: str
    email: EmailStr
    password: str
    role: str

    @field_validator("password")
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password too short")
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str