from utils.database import engine, Base
import models.user
import models.ai_result
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, ai, contents, batch, chat
from routers import batch, chat

app = FastAPI(
    title="KazuAI Platform API",
    description="AIマルチメディア処理SaaSプラットフォーム",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/auth", tags=["認証"])
app.include_router(ai.router, prefix="/ai", tags=["AI処理"])
app.include_router(contents.router, prefix="/contents", tags=["コンテンツ"])
app.include_router(batch.router, prefix="/batch", tags=["バッチ処理"])
app.include_router(chat.router, prefix="/chat", tags=["チャット"])
app.include_router(batch.router)
app.include_router(chat.router)

@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)

@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "KazuAI Platform"}

