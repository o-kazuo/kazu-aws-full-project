import boto3
import os

translate_client = boto3.client('translate', region_name=os.getenv('AWS_REGION', 'ap-northeast-1'))

def translate_text(text: str, source_language: str = 'auto', target_language: str = 'en') -> dict:
    response = translate_client.translate_text(
        Text=text,
        SourceLanguageCode=source_language,
        TargetLanguageCode=target_language
    )
    return response