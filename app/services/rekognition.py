import boto3
import os

rekognition_client = boto3.client('rekognition', region_name=os.getenv('AWS_REGION', 'ap-northeast-1'))

def detect_labels(s3_key: str) -> list:
    response = rekognition_client.detect_labels(
        Image={
            'S3Object': {
                'Bucket': os.getenv('S3_BUCKET_NAME'),
                'Name': s3_key
            }
        },
        MaxLabels=10,
        MinConfidence=70
    )
    return response.get('Labels', [])

def detect_faces(s3_key: str) -> list:
    response = rekognition_client.detect_faces(
        Image={
            'S3Object': {
                'Bucket': os.getenv('S3_BUCKET_NAME'),
                'Name': s3_key
            }
        },
        Attributes=['ALL']
    )
    return response.get('FaceDetails', [])