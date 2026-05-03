from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr
from services.cognito import register_user, login_user

router = APIRouter()

class RegisterRequest(BaseModel):
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

@router.post("/register")
def register(request: RegisterRequest):
    """ユーザー登録"""
    try:
        result = register_user(request.email, request.password)
        return {"message": "登録完了", "user_sub": result["user_sub"]}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login")
def login(request: LoginRequest):
    """ログイン・JWTトークン取得"""
    try:
        tokens = login_user(request.email, request.password)
        return tokens
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))