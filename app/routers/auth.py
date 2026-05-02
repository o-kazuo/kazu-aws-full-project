from fastapi import APIRouter

router = APIRouter()

@router.post("/register")
def register():
    # Phase C で実装
    return {"message": "register"}

@router.post("/login")
def login():
    # Phase C で実装
    return {"message": "login"}