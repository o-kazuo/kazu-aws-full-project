import boto3
import os
import uuid
import time
from botocore.exceptions import ClientError

REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
ACCOUNT_ID = os.environ.get("ACCOUNT_ID", "227811178732")
INPUT_BUCKET = os.environ.get("INPUT_BUCKET", "dev-input-bucket-227811178732")

macie_client = boto3.client("macie2", region_name=REGION)

def scan_for_pii(s3_key: str) -> dict:
    """
    S3ファイルをMacieでスキャンしてPII（個人情報）を検出
    ※ Macieは非同期ジョブのため完了まで待機する
    """
    try:
        job_name = f"macie-scan-{uuid.uuid4()}"

        response = macie_client.create_classification_job(
            name=job_name,
            jobType="ONE_TIME",
            s3JobDefinition={
                "bucketDefinitions": [
                    {
                        "accountId": ACCOUNT_ID,
                        "buckets": [INPUT_BUCKET],
                    }
                ],
                "scoping": {
                    "includes": {
                        "and": [
                            {
                                "simpleScopeTerm": {
                                    "comparator": "EQ",
                                    "key": "OBJECT_KEY",
                                    "values": [s3_key],
                                }
                            }
                        ]
                    }
                },
            },
        )

        job_id = response["jobId"]

        # ジョブ完了まで待機（最大3分）
        for _ in range(36):
            job_response = macie_client.describe_classification_job(jobId=job_id)
            status = job_response["jobStatus"]

            if status == "COMPLETE":
                # findings（検出結果）を取得
                findings_response = macie_client.list_findings(
                    findingCriteria={
                        "criterion": {
                            "classificationDetails.jobId": {
                                "eq": [job_id]
                            }
                        }
                    }
                )
                finding_ids = findings_response.get("findingIds", [])

                pii_detected = len(finding_ids) > 0
                findings_detail = []

                if finding_ids:
                    detail_response = macie_client.get_findings(findingIds=finding_ids[:10])
                    for finding in detail_response.get("findings", []):
                        findings_detail.append({
                            "type": finding.get("type"),
                            "severity": finding.get("severity", {}).get("description"),
                            "title": finding.get("title"),
                        })

                return {
                    "service": "macie",
                    "job_id": job_id,
                    "s3_key": s3_key,
                    "pii_detected": pii_detected,
                    "finding_count": len(finding_ids),
                    "findings": findings_detail,
                    "status": "completed",
                }

            elif status in ["CANCELLED", "COMPLETE_WITH_ERRORS"]:
                raise Exception(f"Macieジョブが異常終了しました: {status}")

            time.sleep(5)

        raise Exception("Macieジョブがタイムアウトしました（3分超過）")

    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        # Macie未有効化の場合は警告として返す
        if error_code == "AccessDeniedException":
            return {
                "service": "macie",
                "s3_key": s3_key,
                "pii_detected": False,
                "status": "skipped",
                "message": "Macieが有効化されていません。AWSコンソールから有効化してください。",
            }
        raise Exception(f"Macie失敗: {e.response['Error']['Message']}")
