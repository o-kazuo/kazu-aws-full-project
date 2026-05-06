import boto3
import os

rekognition_client = boto3.client('rekognition', region_name=os.getenv('AWS_REGION', 'ap-northeast-1'))

def detect_labels(image_bytes: bytes) -> list:
    response = rekognition_client.detect_labels(
        Image={'Bytes': image_bytes},
        MaxLabels=10,
        MinConfidence=70
    )
    return response.get('Labels', [])

def detect_faces(image_bytes: bytes) -> list:
    response = rekognition_client.detect_faces(
        Image={'Bytes': image_bytes},
        Attributes=['ALL']
    )
    return response.get('FaceDetails', [])