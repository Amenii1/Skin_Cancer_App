from sqlalchemy import Column, Date, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class Image(Base):
    __tablename__ = "images"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    path = Column(String, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    # Date déclarée par le patient (prise de vue / observation de la lésion)
    observation_date = Column(Date, nullable=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    body_zone_id = Column(String, nullable=True, index=True)
    body_zone_label = Column(String, nullable=True)
    symptoms_json = Column(Text, nullable=True)
    result = Column(String, nullable=True)
    confidence = Column(Float, nullable=True)

    avis = relationship("Avis", back_populates="image")
