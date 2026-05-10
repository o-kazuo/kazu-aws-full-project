import boto3
import os
from botocore.exceptions import ClientError

REGION = "us-east-1"
TEXTRACT_BUCKET = "dev-textract-227811178732"
INPUT_BUCKET = "dev-textract-227811178732"

textract_client = boto3.client("textract", region_name=REGION)

def extract_text(s3_key: str) -> dict:
    """
    S3のPDF・画像からテキストを抽出（同期・1ページ用）
    対応形式: JPEG / PNG / PDF（1ページ）
    """
    try:
        response = textract_client.detect_document_text(
            Document={
                "S3Object": {
                    "Bucket": INPUT_BUCKET,
                    "Name": s3_key,
                }
            }
        )

        lines = [
            block["Text"]
            for block in response["Blocks"]
            if block["BlockType"] == "LINE"
        ]

        return {
            "service": "textract",
            "type": "extract_text",
            "s3_key": s3_key,
            "text": "\n".join(lines),
            "line_count": len(lines),
            "page_count": 1,
        }

    except ClientError as e:
        raise Exception(f"Textract失敗: {e.response['Error']['Message']}")


def analyze_document(s3_key: str) -> dict:
    """
    S3の文書からテキスト＋テーブル＋フォームを抽出
    対応形式: JPEG / PNG / PDF（1ページ）
    """
    try:
        response = textract_client.analyze_document(
            Document={
                "S3Object": {
                    "Bucket": INPUT_BUCKET,
                    "Name": s3_key,
                }
            },
            FeatureTypes=["TABLES", "FORMS"],
        )

        lines = []
        tables = []
        forms = {}

        current_table = []
        current_row = []

        for block in response["Blocks"]:
            if block["BlockType"] == "LINE":
                lines.append(block["Text"])
            elif block["BlockType"] == "KEY_VALUE_SET":
                if "KEY" in block.get("EntityTypes", []):
                    # フォームのキーバリューペアは簡易的に収集
                    key_text = block.get("Text", "")
                    if key_text:
                        forms[key_text] = ""

        return {
            "service": "textract",
            "type": "analyze_document",
            "s3_key": s3_key,
            "text": "\n".join(lines),
            "line_count": len(lines),
            "form_fields": forms,
            "block_count": len(response["Blocks"]),
        }

    except ClientError as e:
        raise Exception(f"Textract文書分析失敗: {e.response['Error']['Message']}")
