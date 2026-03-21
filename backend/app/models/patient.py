from sqlalchemy import Column, Integer, String, ForeignKey
from app.core.database import Base

class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    type_peau = Column(String)
    antecedents_familiaux = Column(String)