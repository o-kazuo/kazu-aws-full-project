import boto3
import os
from datetime import datetime
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
ENV = os.environ.get("ENV", "dev")

dynamodb = boto3.resource("dynamodb", region_name=REGION)

# テーブル名（Phase Aで作成済み）
USER_USAGE_TABLE = f"{ENV}-user-usage"
PROCESSING_HISTORY_TABLE = f"{ENV}-processing-history"

# Free プランの月間上限
FREE_PLAN_LIMIT = 5

def get_current_year_month() -> str:
    """現在の年月を取得（例: 2026-05）"""
    return datetime.now().strftime("%Y-%m")

def get_usage_count(user_id: str) -> int:
    """
    ユーザーの今月の使用回数を取得
    """
    try:
        table = dynamodb.Table(USER_USAGE_TABLE)
        year_month = get_current_year_month()

        response = table.get_item(
            Key={
                "user_id": user_id,
                "year_month": year_month,
            }
        )
        item = response.get("Item")
        if not item:
            return 0
        return int(item.get("usage_count", 0))

    except ClientError as e:
        raise Exception(f"DynamoDB使用回数取得失敗: {e.response['Error']['Message']}")

def increment_usage(user_id: str) -> int:
    """
    ユーザーの今月の使用回数を+1する
    存在しない場合は新規作成
    戻り値：更新後の使用回数
    """
    try:
        table = dynamodb.Table(USER_USAGE_TABLE)
        year_month = get_current_year_month()

        response = table.update_item(
            Key={
                "user_id": user_id,
                "year_month": year_month,
            },
            UpdateExpression="ADD usage_count :inc SET updated_at = :now",
            ExpressionAttributeValues={
                ":inc": 1,
                ":now": datetime.now().isoformat(),
            },
            ReturnValues="UPDATED_NEW",
        )
        return int(response["Attributes"]["usage_count"])

    except ClientError as e:
        raise Exception(f"DynamoDB使用回数更新失敗: {e.response['Error']['Message']}")

def check_usage_limit(user_id: str, plan: str = "free") -> dict:
    """
    使用制限チェック
    - free: 月5回まで
    - premium: 無制限
    戻り値: {"allowed": bool, "current": int, "limit": int}
    """
    if plan == "premium":
        current = get_usage_count(user_id)
        return {"allowed": True, "current": current, "limit": -1}

    current = get_usage_count(user_id)
    allowed = current < FREE_PLAN_LIMIT

    return {
        "allowed": allowed,
        "current": current,
        "limit": FREE_PLAN_LIMIT,
        "remaining": max(0, FREE_PLAN_LIMIT - current),
    }

def add_processing_history(user_id: str, service: str, result_id: str, status: str) -> None:
    """
    処理履歴をDynamoDBに記録
    """
    try:
        table = dynamodb.Table(PROCESSING_HISTORY_TABLE)
        table.put_item(
            Item={
                "user_id": user_id,
                "created_at": datetime.now().isoformat(),
                "service": service,
                "result_id": result_id,
                "status": status,
            }
        )
    except ClientError as e:
        # 履歴保存失敗はメイン処理に影響させない（ログだけ）
        print(f"[WARNING] 処理履歴の保存失敗: {e.response['Error']['Message']}")

def get_processing_history(user_id: str, limit: int = 20) -> list:
    """
    ユーザーの処理履歴を取得
    """
    try:
        table = dynamodb.Table(PROCESSING_HISTORY_TABLE)
        response = table.query(
            KeyConditionExpression=Key("user_id").eq(user_id),
            ScanIndexForward=False,  # 新しい順
            Limit=limit,
        )
        return response.get("Items", [])

    except ClientError as e:
        raise Exception(f"処理履歴取得失敗: {e.response['Error']['Message']}")

def get_dynamodb_client():
    """DynamoDBクライアントを返す"""
    return boto3.client("dynamodb", region_name=REGION)