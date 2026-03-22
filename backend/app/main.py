from fastapi import FastAPI
from app.core.database import Base, engine
from app.models.utilisateur import Utilisateur
from app.routers import auth, user
from app.models.patient import Patient
from app.models.dermatologue import Dermatologue
from app.routers import profile
from app.routers import image

app = FastAPI()

Base.metadata.create_all(bind=engine)
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(profile.router)
app.include_router(image.router)
@app.get("/")
def home():
    return {"message": "API working 🚀"}

