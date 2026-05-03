from fastapi import APIRouter

router = APIRouter()

@router.post("/upload")
def upload():
    # Phase E で実装
    return {"message": "upload"}

@router.get("/results")
def get_results():
    # Phase E で実装
    return {"message": "results"}

@router.get("/results/{id}")
def get_result(id: str):
    # Phase E で実装
    return {"message": f"result {id}"}

from fastapi import APIRouter, Depends
from utils.auth import get_current_user

router = APIRouter()

@router.post("/upload")
def upload(current_user: dict = Depends(get_current_user)):
    # Phase E で実装
    return {"message": "upload", "user": current_user}

@router.get("/results")
def get_results(current_user: dict = Depends(get_current_user)):
    # Phase E で実装
    return {"message": "results", "user": current_user}

@router.get("/results/{id}")
def get_result(id: str, current_user: dict = Depends(get_current_user)):
    # Phase E で実装
    return {"message": f"result {id}", "user": current_user}