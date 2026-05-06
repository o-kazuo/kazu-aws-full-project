from fastapi import APIRouter

router = APIRouter()

@router.get("/")
def get_contents():
    # Phase G で実装
    return {"message": "contents"}

@router.get("/{id}/download")
def download_content(id: str):
    # Phase G で実装
    return {"message": f"download {id}"}