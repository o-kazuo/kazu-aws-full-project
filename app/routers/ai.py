import uuid
import json
import time
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Query, Body
from sqlalchemy.orm import Session

from utils.auth import get_current_user
from utils.database import get_db
from utils.s3 import upload_file_to_s3, get_presigned_url
from services.rekognition import detect_labels, detect_faces
from services.transcribe import transcribe_audio
from services.translate import translate_text
from services.comprehend import analyze_text, detect_language
from models.ai_result import AiResult

router = APIRouter()

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_AUDIO_TYPES = {"audio/mpeg", "audio/mp4", "audio/wav", "audio/x-flac", "video/mp4"}

# ============================================================
# POST /ai/upload  — 画像アップロード + Rekognition分析
# ============================================================
@router.post("/upload")
def upload(
    file: UploadFile = File(...),
    analysis_type: str = Query(default="labels", enum=["labels", "faces"]),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="JPEG・PNG・WebP・GIFのみ対応しています")

    ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    s3_key = f"{current_user['sub']}/{uuid.uuid4()}.{ext}"

    ai_result = AiResult(
        user_id=current_user["sub"],
        service="rekognition",
        input_s3_key=s3_key,
        status="processing",
    )
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        file_bytes = file.file.read()
        upload_file_to_s3(file_bytes, s3_key, file.content_type)

        start = time.time()
        result = detect_faces(s3_key) if analysis_type == "faces" else detect_labels(s3_key)
        processing_time = round(time.time() - start, 2)

        ai_result.result = json.dumps(result, ensure_ascii=False)
        ai_result.status = "completed"
        ai_result.processing_time = processing_time
        db.commit()
        db.refresh(ai_result)

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "result": result}

    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/transcribe  — 音声ファイル → テキスト変換
# ============================================================
@router.post("/transcribe")
def transcribe(
    file: UploadFile = File(...),
    language_code: str = Query(default="ja-JP", enum=["ja-JP", "en-US", "zh-CN", "ko-KR"]),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if file.content_type not in ALLOWED_AUDIO_TYPES:
        raise HTTPException(status_code=400, detail="MP3・MP4・WAV・FLACのみ対応しています")

    ext = file.filename.split(".")[-1] if "." in file.filename else "mp3"
    s3_key = f"{current_user['sub']}/audio/{uuid.uuid4()}.{ext}"

    ai_result = AiResult(
        user_id=current_user["sub"],
        service="transcribe",
        input_s3_key=s3_key,
        status="processing",
    )
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        file_bytes = file.file.read()
        upload_file_to_s3(file_bytes, s3_key, file.content_type)

        start = time.time()
        result = transcribe_audio(s3_key, language_code)
        processing_time = round(time.time() - start, 2)

        ai_result.result = json.dumps(result, ensure_ascii=False)
        ai_result.status = "completed"
        ai_result.processing_time = processing_time
        db.commit()
        db.refresh(ai_result)

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "result": result}

    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/translate  — テキスト翻訳
# ============================================================
@router.post("/translate")
def translate(
    text: str = Body(..., embed=True),
    target_language: str = Body(default="en", embed=True),
    source_language: str = Body(default="auto", embed=True),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ai_result = AiResult(
        user_id=current_user["sub"],
        service="translate",
        status="processing",
    )
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        start = time.time()
        result = translate_text(text, target_language, source_language)
        processing_time = round(time.time() - start, 2)

        ai_result.result = json.dumps(result, ensure_ascii=False)
        ai_result.status = "completed"
        ai_result.processing_time = processing_time
        db.commit()
        db.refresh(ai_result)

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "result": result}

    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/comprehend  — テキスト感情・エンティティ分析
# ============================================================
@router.post("/comprehend")
def comprehend(
    text: str = Body(..., embed=True),
    language_code: str = Body(default="ja", embed=True),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    ai_result = AiResult(
        user_id=current_user["sub"],
        service="comprehend",
        status="processing",
    )
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        start = time.time()
        result = analyze_text(text, language_code)
        processing_time = round(time.time() - start, 2)

        ai_result.result = json.dumps(result, ensure_ascii=False)
        ai_result.status = "completed"
        ai_result.processing_time = processing_time
        db.commit()
        db.refresh(ai_result)

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "result": result}

    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET /ai/results  — 自分の結果一覧
# ============================================================
@router.get("/results")
def get_results(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = Query(default=20, le=100),
):
    results = (
        db.query(AiResult)
        .filter(AiResult.user_id == current_user["sub"])
        .order_by(AiResult.created_at.desc())
        .limit(limit)
        .all()
    )
    return {"results": [r.to_dict() for r in results], "count": len(results)}


# ============================================================
# GET /ai/results/{id}  — 特定の結果を取得
# ============================================================
@router.get("/results/{id}")
def get_result(
    id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    result = db.query(AiResult).filter(
        AiResult.id == id,
        AiResult.user_id == current_user["sub"],
    ).first()

    if not result:
        raise HTTPException(status_code=404, detail="結果が見つかりません")

    result_dict = result.to_dict()
    if result.status == "completed" and result.input_s3_key:
        result_dict["download_url"] = get_presigned_url(result.input_s3_key)

    return result_dict
