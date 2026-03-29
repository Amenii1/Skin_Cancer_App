from sqlalchemy import Column, Integer, String, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class Avis(Base):
    __tablename__ = "avis"

    id = Column(Integer, primary_key=True, index=True)

    image_id = Column(Integer, ForeignKey("images.id"), nullable=False)
    dermatologue_id = Column(Integer, ForeignKey("dermatologues.id"), nullable=False)

    commentaire = Column(Text, nullable=False)
    diagnostic = Column(String, nullable=False)

    # 🔗 relations
    image = relationship("Image", back_populates="avis")
    dermatologue = relationship("Dermatologue", back_populates="avis")