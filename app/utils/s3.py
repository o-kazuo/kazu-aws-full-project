import boto3
import io
import os

s3_client = boto3.client('s3', region_name=os.getenv('AWS_REGION', 'ap-northeast-1'))
BUCKET_NAME = os.getenv('S3_BUCKET_NAME', '')

def upload_file_to_s3(data: bytes, key: str, content_type: str = 'application/octet-stream', bucket: str = None) -> str:
    target_bucket = bucket or BUCKET_NAME
    s3_client.upload_fileobj(io.BytesIO(data), target_bucket, key, ExtraArgs={'ContentType': content_type})
    return f"s3://{target_bucket}/{key}"

def get_presigned_url(key: str, expiration: int = 3600) -> str:
    return s3_client.generate_presigned_url('get_object', Params={'Bucket': BUCKET_NAME, 'Key': key}, ExpiresIn=expiration)
