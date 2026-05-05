import boto3
import os
import uuid
import json
import urllib.request

transcribe_client = boto3.client('transcribe', region_name=os.getenv('AWS_REGION', 'ap-northeast-1'))

def transcribe_audio(s3_uri: str, language_code: str = 'ja-JP') -> str:
    job_name = f"transcribe-{uuid.uuid4().hex}"
    transcribe_client.start_transcription_job(
        TranscriptionJobName=job_name,
        Media={'MediaFileUri': s3_uri},
        MediaFormat='mp3',
        LanguageCode=language_code
    )
    while True:
        response = transcribe_client.get_transcription_job(TranscriptionJobName=job_name)
        status = response['TranscriptionJob']['TranscriptionJobStatus']
        if status == 'COMPLETED':
            transcript_uri = response['TranscriptionJob']['Transcript']['TranscriptFileUri']
            with urllib.request.urlopen(transcript_uri) as f:
                result = json.loads(f.read().decode())
            return result['results']['transcripts'][0]['transcript']
        elif status == 'FAILED':
            raise Exception('Transcription failed')
        import time
        time.sleep(2)