from sqlalchemy import Column, Integer, String, ForeignKey
from app.core.database import Base

class Image(Base):
    __tablename__ = "images"

    id = Column(Integer, primary_key=True, index=True)
    path = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))