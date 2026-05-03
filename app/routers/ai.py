import uuid
import json
import time
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, Query, Body
from sqlalchemy.orm import Session

from utils.auth import get_current_user
from utils.database import get_db
from utils.s3 import upload_file_to_s3, get_presigned_url
from utils.dynamodb import check_usage_limit, increment_usage, add_processing_history
from services.rekognition import detect_labels, detect_faces
from services.transcribe import transcribe_audio
from services.translate import translate_text
from services.comprehend import analyze_text
from services.textract import extract_text, analyze_document
from services.bedrock import generate_text, summarize_text
from services.macie import scan_for_pii
from models.ai_result import AiResult

router = APIRouter()

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
ALLOWED_AUDIO_TYPES = {"audio/mpeg", "audio/mp4", "audio/wav", "audio/x-flac", "video/mp4"}
ALLOWED_DOCUMENT_TYPES = {"image/jpeg", "image/png", "application/pdf"}


def check_limit(user: dict):
    """使用回数チェック共通処理（Free: 5回/月）"""
    plan = user.get("plan", "free")
    result = check_usage_limit(user["sub"], plan)
    if not result["allowed"]:
        raise HTTPException(
            status_code=429,
            detail=f"月間使用回数の上限（{result['limit']}回）に達しました。Premiumにアップグレードしてください。"
        )
    return result


def finalize(ai_result, result, processing_time, db, user_id, service):
    """処理完了時の共通後処理"""
    ai_result.result = json.dumps(result, ensure_ascii=False)
    ai_result.status = "completed"
    ai_result.processing_time = processing_time
    db.commit()
    db.refresh(ai_result)
    new_count = increment_usage(user_id)
    add_processing_history(user_id, service, ai_result.id, "completed")
    return new_count


# ============================================================
# POST /ai/upload  — 画像 + Rekognition分析
# ============================================================
@router.post("/upload")
def upload(
    file: UploadFile = File(...),
    analysis_type: str = Query(default="labels", enum=["labels", "faces"]),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_limit(current_user)
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="JPEG・PNG・WebP・GIFのみ対応しています")

    ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    s3_key = f"{current_user['sub']}/{uuid.uuid4()}.{ext}"

    ai_result = AiResult(user_id=current_user["sub"], service="rekognition",
                         input_s3_key=s3_key, status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        upload_file_to_s3(file.file.read(), s3_key, file.content_type)
        start = time.time()
        result = detect_faces(s3_key) if analysis_type == "faces" else detect_labels(s3_key)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "rekognition")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/transcribe  — 音声 → テキスト変換
# ============================================================
@router.post("/transcribe")
def transcribe(
    file: UploadFile = File(...),
    language_code: str = Query(default="ja-JP", enum=["ja-JP", "en-US", "zh-CN", "ko-KR"]),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_limit(current_user)
    if file.content_type not in ALLOWED_AUDIO_TYPES:
        raise HTTPException(status_code=400, detail="MP3・MP4・WAV・FLACのみ対応しています")

    ext = file.filename.split(".")[-1] if "." in file.filename else "mp3"
    s3_key = f"{current_user['sub']}/audio/{uuid.uuid4()}.{ext}"

    ai_result = AiResult(user_id=current_user["sub"], service="transcribe",
                         input_s3_key=s3_key, status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        upload_file_to_s3(file.file.read(), s3_key, file.content_type)
        start = time.time()
        result = transcribe_audio(s3_key, language_code)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "transcribe")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
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
    check_limit(current_user)
    ai_result = AiResult(user_id=current_user["sub"], service="translate", status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        start = time.time()
        result = translate_text(text, target_language, source_language)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "translate")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
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
    check_limit(current_user)
    ai_result = AiResult(user_id=current_user["sub"], service="comprehend", status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        start = time.time()
        result = analyze_text(text, language_code)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "comprehend")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/textract  — 文書・PDF テキスト抽出
# ============================================================
@router.post("/textract")
def textract(
    file: UploadFile = File(...),
    mode: str = Query(default="extract", enum=["extract", "analyze"]),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_limit(current_user)
    if file.content_type not in ALLOWED_DOCUMENT_TYPES:
        raise HTTPException(status_code=400, detail="JPEG・PNG・PDFのみ対応しています")

    ext = file.filename.split(".")[-1] if "." in file.filename else "pdf"
    s3_key = f"{current_user['sub']}/documents/{uuid.uuid4()}.{ext}"

    ai_result = AiResult(user_id=current_user["sub"], service="textract",
                         input_s3_key=s3_key, status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        upload_file_to_s3(file.file.read(), s3_key, file.content_type)
        start = time.time()
        result = analyze_document(s3_key) if mode == "analyze" else extract_text(s3_key)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "textract")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/bedrock  — 生成AI（Claude 3 Haiku）
# ============================================================
@router.post("/bedrock")
def bedrock(
    prompt: str = Body(..., embed=True),
    mode: str = Body(default="generate", embed=True),
    text_to_summarize: str = Body(default=None, embed=True),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_limit(current_user)
    ai_result = AiResult(user_id=current_user["sub"], service="bedrock", status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        start = time.time()
        result = summarize_text(text_to_summarize) if mode == "summarize" and text_to_summarize else generate_text(prompt)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "bedrock")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# POST /ai/macie  — PII（個人情報）検出
# ============================================================
@router.post("/macie")
def macie(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    check_limit(current_user)
    ext = file.filename.split(".")[-1] if "." in file.filename else "txt"
    s3_key = f"{current_user['sub']}/macie/{uuid.uuid4()}.{ext}"

    ai_result = AiResult(user_id=current_user["sub"], service="rekognition",
                         input_s3_key=s3_key, status="processing")
    db.add(ai_result)
    db.commit()
    db.refresh(ai_result)

    try:
        upload_file_to_s3(file.file.read(), s3_key, file.content_type)
        start = time.time()
        result = scan_for_pii(s3_key)
        processing_time = round(time.time() - start, 2)
        new_count = finalize(ai_result, result, processing_time, db, current_user["sub"], "macie")

        return {"result_id": ai_result.id, "status": "completed",
                "processing_time": processing_time, "usage_count": new_count, "result": result}
    except HTTPException:
        raise
    except Exception as e:
        ai_result.status = "failed"
        ai_result.result = json.dumps({"error": str(e)}, ensure_ascii=False)
        db.commit()
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# GET /ai/usage  — 今月の使用回数確認
# ============================================================
@router.get("/usage")
def get_usage(current_user: dict = Depends(get_current_user)):
    plan = current_user.get("plan", "free")
    result = check_usage_limit(current_user["sub"], plan)
    return {"user": current_user["email"], "plan": plan, **result}


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
