import boto3
import hmac
import hashlib
import base64
from botocore.exceptions import ClientError

USER_POOL_ID = "ap-northeast-1_QlvfQKQso"
CLIENT_ID = "fo8ldlqf7qqgmcoj9gi2nfs3s"
REGION = "ap-northeast-1"

client = boto3.client("cognito-idp", region_name=REGION)

def register_user(email: str, password: str) -> dict:
    """ユーザー登録"""
    try:
        response = client.sign_up(
            ClientId=CLIENT_ID,
            Username=email,
            Password=password,
            UserAttributes=[
                {"Name": "email", "Value": email}
            ]
        )
        # 自動確認（開発環境用）
        client.admin_confirm_sign_up(
            UserPoolId=USER_POOL_ID,
            Username=email
        )
        return {"success": True, "user_sub": response["UserSub"]}
    except ClientError as e:
        raise Exception(e.response["Error"]["Message"])

def login_user(email: str, password: str) -> dict:
    """ログイン・JWT取得"""
    try:
        response = client.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME": email,
                "PASSWORD": password
            }
        )
        tokens = response["AuthenticationResult"]
        return {
            "access_token": tokens["AccessToken"],
            "id_token": tokens["IdToken"],
            "refresh_token": tokens["RefreshToken"],
            "token_type": "Bearer"
        }
    except ClientError as e:
        raise Exception(e.response["Error"]["Message"])

def get_user(access_token: str) -> dict:
    """JWTからユーザー情報取得"""
    try:
        response = client.get_user(AccessToken=access_token)
        attributes = {attr["Name"]: attr["Value"] for attr in response["UserAttributes"]}
        return {
            "username": response["Username"],
            "email": attributes.get("email"),
            "sub": attributes.get("sub")
        }
    except ClientError as e:
        raise Exception(e.response["Error"]["Message"])