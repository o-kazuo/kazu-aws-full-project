from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
import boto3
import uuid
import os
from datetime import datetime
from utils.auth import get_current_user
from utils.dynamodb import get_dynamodb_client

router = APIRouter(prefix="/chat", tags=["chat"])

lex_client = boto3.client("lexv2-runtime", region_name="ap-northeast-1")


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


@router.post("/message")
async def send_message(
    req: ChatRequest,
    current_user: dict = Depends(get_current_user)
):
    """Lexチャットボットにメッセージを送信する"""
    bot_id      = os.environ.get("LEX_BOT_ID", "")
    bot_alias_id = os.environ.get("LEX_BOT_ALIAS_ID", "TSTALIASID")
    locale_id   = "ja_JP"

    if not bot_id:
        raise HTTPException(status_code=500, detail="LEX_BOT_ID が設定されていません")

    session_id = req.session_id or f"{current_user['sub']}-{uuid.uuid4().hex[:8]}"
    user_id    = current_user.get("sub", "unknown")

    try:
        resp = lex_client.recognize_text(
            botId=bot_id,
            botAliasId=bot_alias_id,
            localeId=locale_id,
            sessionId=session_id,
            text=req.message,
        )

        # レスポンスメッセージを結合
        messages = resp.get("messages", [])
        bot_reply = "\n".join([m.get("content", "") for m in messages]) or "返答がありません"

        intent_name = resp.get("sessionState", {}).get("intent", {}).get("name", "")

        # DynamoDBにチャット履歴を保存
        await _save_chat_history(user_id, req.message, bot_reply, session_id, intent_name)

        return {
            "session_id":   session_id,
            "user_message": req.message,
            "bot_reply":    bot_reply,
            "intent":       intent_name,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"チャットエラー: {str(e)}")


@router.get("/history")
async def get_chat_history(
    current_user: dict = Depends(get_current_user)
):
    """チャット履歴を取得する"""
    user_id = current_user.get("sub", "unknown")

    try:
        dynamodb = get_dynamodb_client()
        table    = dynamodb.Table("dev-chat-history")
        resp     = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key("user_id").eq(user_id),
            ScanIndexForward=False,
            Limit=50,
        )
        return {"history": resp.get("Items", []), "count": resp.get("Count", 0)}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"履歴取得エラー: {str(e)}")


async def _save_chat_history(
    user_id: str, user_msg: str, bot_reply: str, session_id: str, intent: str
):
    """DynamoDBにチャット履歴を保存する（dev-chat-history テーブル）"""
    try:
        dynamodb  = get_dynamodb_client()
        table     = dynamodb.Table("dev-chat-history")
        timestamp = datetime.utcnow().isoformat()

        table.put_item(Item={
            "user_id":      user_id,
            "timestamp":    timestamp,
            "session_id":   session_id,
            "user_message": user_msg,
            "bot_reply":    bot_reply,
            "intent":       intent,
        })
    except Exception:
        pass  # 保存失敗は握りつぶし（チャット本体への影響を防ぐ）