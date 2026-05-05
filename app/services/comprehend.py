import boto3
import os

comprehend_client = boto3.client('comprehend', region_name=os.getenv('AWS_REGION', 'ap-northeast-1'))

def analyze_text(text: str, language_code: str = 'ja') -> dict:
    sentiment = comprehend_client.detect_sentiment(Text=text, LanguageCode=language_code)
    entities = comprehend_client.detect_entities(Text=text, LanguageCode=language_code)
    return {
        'sentiment': sentiment.get('Sentiment'),
        'sentimentScore': sentiment.get('SentimentScore'),
        'entities': entities.get('Entities', [])
    }
