from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
import boto3
import uuid
from utils.auth import get_current_user

router = APIRouter(prefix="/batch", tags=["batch"])

batch_client = boto3.client("batch", region_name="ap-northeast-1")


class BatchSubmitRequest(BaseModel):
    job_name: Optional[str] = None
    command: Optional[list[str]] = None
    environment: Optional[dict] = None


@router.post("/submit")
async def submit_batch_job(
    req: BatchSubmitRequest,
    current_user: dict = Depends(get_current_user)
):
    """バッチジョブを投入する"""
    import os
    job_queue      = os.environ.get("BATCH_JOB_QUEUE",      "dev-batch-queue")
    job_definition = os.environ.get("BATCH_JOB_DEFINITION", "dev-batch-job")

    job_name = req.job_name or f"kazu-job-{uuid.uuid4().hex[:8]}"

    container_overrides: dict = {}
    if req.command:
        container_overrides["command"] = req.command
    if req.environment:
        container_overrides["environment"] = [
            {"name": k, "value": v} for k, v in req.environment.items()
        ]

    try:
        resp = batch_client.submit_job(
            jobName=job_name,
            jobQueue=job_queue,
            jobDefinition=job_definition,
            containerOverrides=container_overrides if container_overrides else {},
        )
        return {
            "job_id":   resp["jobId"],
            "job_name": resp["jobName"],
            "status":   "SUBMITTED",
            "message":  "バッチジョブを投入しました",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ジョブ投入エラー: {str(e)}")


@router.get("/status/{job_id}")
async def get_batch_job_status(
    job_id: str,
    current_user: dict = Depends(get_current_user)
):
    """バッチジョブのステータスを確認する"""
    try:
        resp = batch_client.describe_jobs(jobs=[job_id])
        if not resp["jobs"]:
            raise HTTPException(status_code=404, detail="ジョブが見つかりません")

        job = resp["jobs"][0]
        return {
            "job_id":     job["jobId"],
            "job_name":   job["jobName"],
            "status":     job["status"],
            "created_at": job.get("createdAt"),
            "started_at": job.get("startedAt"),
            "stopped_at": job.get("stoppedAt"),
            "status_reason": job.get("statusReason", ""),
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ステータス確認エラー: {str(e)}")


@router.get("/list")
async def list_batch_jobs(
    current_user: dict = Depends(get_current_user)
):
    """ジョブ一覧を取得する（直近のSUBMITTED/RUNNING/SUCCEEDED/FAILED）"""
    import os
    job_queue = os.environ.get("BATCH_JOB_QUEUE", "dev-batch-queue")

    results = []
    for status in ["SUBMITTED", "PENDING", "RUNNABLE", "STARTING", "RUNNING", "SUCCEEDED", "FAILED"]:
        try:
            resp = batch_client.list_jobs(jobQueue=job_queue, jobStatus=status)
            results.extend([
                {"job_id": j["jobId"], "job_name": j["jobName"], "status": status}
                for j in resp.get("jobSummaryList", [])
            ])
        except Exception:
            pass

    return {"jobs": results, "total": len(results)}