from fastapi import APIRouter

router = APIRouter()

@router.post("/upload")
def upload():
    # Phase E で実装
    return {"message": "upload"}

@router.get("/results")
def get_results():
    # Phase E で実装
    return {"message": "results"}

@router.get("/results/{id}")
def get_result(id: str):
    # Phase E で実装
    return {"message": f"result {id}"}