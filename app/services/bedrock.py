import boto3
import os
import json
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")

bedrock_client = boto3.client("bedrock-runtime", region_name=REGION)

# 使用するモデル（Claude 3 Haiku — コスト最小・高速）
MODEL_ID = "anthropic.claude-haiku-4-5-20251001-v1:0"

def generate_text(prompt: str, max_tokens: int = 1000, system_prompt: str = None) -> dict:
    """
    Bedrockを使ってテキスト生成（Claude 3 Haiku）
    """
    try:
        messages = [{"role": "user", "content": prompt}]

        body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "messages": messages,
        }

        if system_prompt:
            body["system"] = system_prompt

        response = bedrock_client.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps(body),
        )

        result = json.loads(response["body"].read().decode("utf-8"))
        generated_text = result["content"][0]["text"]
        usage = result.get("usage", {})

        return {
            "service": "bedrock",
            "model_id": MODEL_ID,
            "prompt": prompt,
            "generated_text": generated_text,
            "input_tokens": usage.get("input_tokens", 0),
            "output_tokens": usage.get("output_tokens", 0),
        }

    except ClientError as e:
        raise Exception(f"Bedrock失敗: {e.response['Error']['Message']}")


def summarize_text(text: str, language: str = "ja") -> dict:
    """
    テキストを要約する（Textractの結果などを渡すユースケース）
    """
    lang_instruction = "日本語" if language == "ja" else "English"
    prompt = f"以下のテキストを{lang_instruction}で簡潔に要約してください。\n\n{text}"

    result = generate_text(
        prompt=prompt,
        max_tokens=500,
        system_prompt="あなたは優秀な文書要約アシスタントです。簡潔で正確な要約を提供してください。",
    )
    result["type"] = "summarize"
    return result


def analyze_sentiment_with_ai(text: str) -> dict:
    """
    AIによる感情・トーン分析（Comprehendより詳細なコメント付き）
    """
    prompt = f"以下のテキストの感情・トーンを分析し、ポジティブ/ネガティブ/ニュートラルの判定とその理由を日本語で説明してください。\n\n{text}"

    result = generate_text(
        prompt=prompt,
        max_tokens=300,
        system_prompt="あなたはテキスト感情分析の専門家です。",
    )
    result["type"] = "sentiment_analysis"
    return result
