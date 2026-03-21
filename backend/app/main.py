from fastapi import FastAPI
from app.core.database import Base, engine
from app.models.utilisateur import Utilisateur
from app.routers import auth, user
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue

app = FastAPI()

Base.metadata.create_all(bind=engine)
app.include_router(auth.router)
app.include_router(user.router)



@app.get("/")
def home():
    return {"message": "API working 🚀"}

