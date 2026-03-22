from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from sqlalchemy.orm import Session
import base64, os
from uuid import uuid4
from app.core.dependencies import get_current_user,get_db
from app.models.image import Image

router = APIRouter(prefix="/image", tags=["Image"])

UPLOAD_DIR = "uploads"

if not os.path.exists(UPLOAD_DIR):
    os.makedirs(UPLOAD_DIR)

@router.post("/upload")
async def upload_image(
    file: UploadFile = File(None),
    base64_image: str = Form(None),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # 🔥 CHECK ROLE
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can upload images")

    filename = f"{uuid4()}.jpg"
    file_path = os.path.join(UPLOAD_DIR, filename)

    # 📸 FILE
    if file:
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())

    # 📸 BASE64
    elif base64_image:
        image_data = base64.b64decode(base64_image)
        with open(file_path, "wb") as f:
            f.write(image_data)

    else:
        raise HTTPException(status_code=400, detail="No image provided")

    # 💾 save in DB
    new_image = Image(
        user_id=current_user.id,
        path=file_path
    )

    db.add(new_image)
    db.commit()

    return {
        "message": "Image uploaded successfully",
        "image_id": new_image.id,
        "path": file_path
    }