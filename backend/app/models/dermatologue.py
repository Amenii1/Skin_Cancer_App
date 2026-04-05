from sqlalchemy import Column, Integer, String, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


class Dermatologue(Base):
    __tablename__ = "dermatologues"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    specialite = Column(String, nullable=True)
    adresse_cabinet = Column(String, nullable=True)
    ville = Column(String, nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    numero_rpps = Column(String, nullable=True)

    # 🔗 relation
    user = relationship("Utilisateur", back_populates="dermatologue")
    avis = relationship("Avis", back_populates="dermatologue")