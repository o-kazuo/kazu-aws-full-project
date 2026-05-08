import boto3
import os
import json
import logging
from PIL import Image
import io
from datetime import datetime, timezone
import traceback

# ロガー設定
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# クライアント初期化（Lambda実行環境で再利用される）
s3 = boto3.client('s3')
sns = boto3.client('sns')
rekognition = boto3.client('rekognition')
dynamodb = boto3.resource('dynamodb')

# 環境変数
OUTPUT_BUCKET  = os.environ['OUTPUT_BUCKET']
SNS_TOPIC_ARN  = os.environ['SNS_TOPIC_ARN']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']

# DynamoDBテーブル
table = dynamodb.Table(DYNAMODB_TABLE)


def process_image(input_bucket: str, key: str) -> dict:
    """
    1枚の画像を処理する。
    - S3から取得
    - リサイズしてoutputバケットに保存
    - Rekognitionで画像分析
    - DynamoDBに結果保存
    - SNS通知
    """
    logger.info(f"処理開始: bucket={input_bucket}, key={key}")

    # --- S3から画像取得 ---
    response = s3.get_object(Bucket=input_bucket, Key=key)
    image_data = response['Body'].read()
    content_type = response.get('ContentType', 'image/jpeg')

    # --- リサイズ ---
    image = Image.open(io.BytesIO(image_data))
    original_size = image.size
    original_format = image.format or 'JPEG'

    image_copy = image.copy()
    image_copy.thumbnail((800, 600))
    resized_size = image_copy.size

    buffer = io.BytesIO()
    image_copy.save(buffer, format=original_format)
    buffer.seek(0)

    output_key = f"resized/{key}"
    s3.put_object(
        Bucket=OUTPUT_BUCKET,
        Key=output_key,
        Body=buffer,
        ContentType=content_type
    )
    logger.info(f"リサイズ完了: {original_size} -> {resized_size}, 保存先={output_key}")

    # --- Rekognition分析 ---
    rekognition_response = rekognition.detect_labels(
        Image={'S3Object': {'Bucket': input_bucket, 'Name': key}},
        MaxLabels=10,
        MinConfidence=70.0
    )
    labels = rekognition_response.get('Labels', [])
    top_label = labels[0]['Name'] if labels else 'Unknown'
    logger.info(f"Rekognition結果: {[l['Name'] for l in labels]}")

    # --- DynamoDB保存 ---
    analyzed_at = datetime.now(timezone.utc).isoformat()
    # TTL: 90日後に自動削除
    expires_at = int(
        datetime.now(timezone.utc).timestamp() + 60 * 60 * 24 * 90
    )

    table.put_item(Item={
        'image_key'    : key,
        'analyzed_at'  : analyzed_at,
        'input_bucket' : input_bucket,
        'output_key'   : output_key,
        'original_size': f"{original_size[0]}x{original_size[1]}",
        'resized_size' : f"{resized_size[0]}x{resized_size[1]}",
        'top_label'    : top_label,
        'labels'       : [
            {'name': l['Name'], 'confidence': str(l['Confidence'])}
            for l in labels
        ],
        'expires_at'   : expires_at
    })
    logger.info(f"DynamoDB保存完了: key={key}")

    # --- SNS通知 ---
    label_summary = ', '.join([
        f"{l['Name']}({l['Confidence']:.1f}%)" for l in labels[:3]
    ])
    message = (
        f"画像処理が完了しました\n"
        f"ファイル名: {key}\n"
        f"元のサイズ: {original_size[0]}x{original_size[1]}px\n"
        f"リサイズ後: {resized_size[0]}x{resized_size[1]}px\n"
        f"検出ラベル: {label_summary}\n"
        f"保存先: s3://{OUTPUT_BUCKET}/{output_key}"
    )
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='【KazuAI】画像処理完了通知',
        Message=message
    )

    return {
        'key'        : key,
        'output_key' : output_key,
        'top_label'  : top_label,
        'labels'     : [l['Name'] for l in labels]
    }


def lambda_handler(event, context):
    """
    S3イベントから複数レコードを処理する。
    各レコードを個別に処理しエラーがあっても続行する。
    """
    records = event.get('Records', [])
    logger.info(f"受信レコード数: {len(records)}")

    results = []
    errors  = []

    for record in records:
        input_bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        try:
            result = process_image(input_bucket, key)
            results.append(result)
        except Exception as e:
            # 1件失敗しても他の処理は続ける
            logger.error(
                f"処理失敗: key={key}, error={str(e)}\n"
                f"{traceback.format_exc()}"
            )
            errors.append({'key': key, 'error': str(e)})
        except Exception as e:
            # 1件失敗しても他の処理は続ける
            logger.error(
                f"処理失敗: key={key}, error={str(e)}\n"
                f"{traceback.format_exc()}"
            )
            errors.append({'key': key, 'error': str(e)})

            # エラーをSNSで通知
            try:
                sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject='【KazuAI】⚠️ 画像処理エラー通知',
                    Message=(
                        f"画像処理中にエラーが発生しました\n"
                        f"ファイル名: {key}\n"
                        f"バケット: {input_bucket}\n"
                        f"エラー内容: {str(e)}\n"
                        f"詳細:\n{traceback.format_exc()}"
                    )
                )
            except Exception as sns_error:
                # SNS通知自体が失敗してもログだけ残す
                logger.error(f"SNSエラー通知失敗: {str(sns_error)}")

    logger.info(f"処理完了: 成功={len(results)}, 失敗={len(errors)}")

    return {
        'statusCode': 200 if not errors else 207,
        'body': json.dumps({
            'processed': len(results),
            'errors'   : len(errors),
            'results'  : results,
            'error_details': errors
        }, ensure_ascii=False)
    }