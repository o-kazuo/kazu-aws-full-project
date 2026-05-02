from fastapi import APIRouter

router = APIRouter()

@router.post("/")
def chat():
    # Phase K で実装
    return {"message": "chat"}