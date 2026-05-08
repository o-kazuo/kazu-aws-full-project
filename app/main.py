from utils.database import engine, Base
import models.user
import models.ai_result
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, ai, contents, batch, chat
from alembic.config import Config
from alembic import command

app = FastAPI(
    title="KazuAI Platform API",
    description="AIマルチメディア処理SaaSプラットフォーム",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://dbpdphg1z541d.cloudfront.net"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,     prefix="/api/auth",     tags=["認証"])
app.include_router(ai.router,       prefix="/api/ai",       tags=["AI処理"])
app.include_router(contents.router, prefix="/api/contents", tags=["コンテンツ"])
app.include_router(batch.router,    prefix="/api/batch",    tags=["バッチ処理"])
app.include_router(chat.router,     prefix="/api/chat",     tags=["チャット"])

@app.on_event("startup")
def startup():
    # Alembicマイグレーション実行
    alembic_cfg = Config("/app/alembic.ini")
    alembic_cfg.set_main_option("script_location", "/app/migrations")
    command.upgrade(alembic_cfg, "head")

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": "KazuAI Platform"}
