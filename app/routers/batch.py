from fastapi import APIRouter

router = APIRouter()

@router.post("/submit")
def submit_batch():
    # Phase K で実装
    return {"message": "batch submit"}

@router.get("/status/{job_id}")
def get_batch_status(job_id: str):
    # Phase K で実装
    return {"message": f"batch status {job_id}"}