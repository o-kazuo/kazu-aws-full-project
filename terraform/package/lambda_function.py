import boto3
import os
import json
from PIL import Image
import io

s3 = boto3.client('s3')
sns = boto3.client('sns')

OUTPUT_BUCKET = os.environ['OUTPUT_BUCKET']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    # S3からアップロードされたファイル情報を取得
    record = event['Records'][0]
    input_bucket = record['s3']['bucket']['name']
    key = record['s3']['object']['key']
    
    # S3から画像を取得
    response = s3.get_object(Bucket=input_bucket, Key=key)
    image_data = response['Body'].read()
    
    # 画像をリサイズ（800x600に縮小）
    image = Image.open(io.BytesIO(image_data))
    original_size = image.size
    image.thumbnail((800, 600))
    resized_size = image.size
    
    # リサイズ後の画像を出力バケットに保存
    output_key = f"resized/{key}"
    buffer = io.BytesIO()
    image.save(buffer, format=image.format or 'JPEG')
    buffer.seek(0)
    
    s3.put_object(
        Bucket=OUTPUT_BUCKET,
        Key=output_key,
        Body=buffer,
        ContentType=response['ContentType']
    )
    
    # SNSで通知
    message = f"""
画像のリサイズが完了しました！

ファイル名: {key}
元のサイズ: {original_size[0]}x{original_size[1]}px
リサイズ後: {resized_size[0]}x{resized_size[1]}px
保存先: s3://{OUTPUT_BUCKET}/{output_key}
"""
    
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='【Kazu AWS】画像リサイズ完了通知',
        Message=message
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Success!')
    }