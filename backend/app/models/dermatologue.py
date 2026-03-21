from sqlalchemy import Column, Integer, String, ForeignKey
from app.core.database import Base

class Dermatologue(Base):
    __tablename__ = "dermatologues"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    specialite = Column(String)
    adresse_cabinet = Column(String)