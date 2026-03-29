from pydantic import BaseModel
from datetime import datetime

class ReservationCreate(BaseModel):
    dermatologue_id: int
    date_rdv: datetime


class ReservationUpdate(BaseModel):
    status: str  # accepted / refused