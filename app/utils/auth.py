from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from services.cognito import get_user

security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)) -> dict:
    """JWTトークンを検証してユーザー情報を返す"""
    token = credentials.credentials
    try:
        user = get_user(access_token=token)
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail=str(e))