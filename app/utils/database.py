import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

def _build_url(env_key: str, fallback: str) -> str:
    url = os.getenv(env_key, fallback)
    url = url.replace("mysql+pymysql://", "mysql+mysqldb://")
    url = url.replace("mysql://", "mysql+mysqldb://")
    return url

SSL_ARGS = {
    "ssl": {
        "ca": "/etc/ssl/certs/ca-certificates.crt"
    }
}

# Writer（書き込み用）
DATABASE_URL_WRITER = _build_url(
    "DATABASE_URL_WRITER",
    "mysql://admin:password@localhost:3306/kazudb"
)
engine_writer = create_engine(DATABASE_URL_WRITER, connect_args=SSL_ARGS)
SessionWriter = sessionmaker(autocommit=False, autoflush=False, bind=engine_writer)

# Reader（読み込み用）- Aurora Serverless v2単一インスタンスのためWriterを使用
DATABASE_URL_READER = _build_url(
    "DATABASE_URL_WRITER",  # 本番ではDATA_URL_READERに変更してReaderインスタンスを追加
    "mysql://admin:password@localhost:3306/kazudb"
)
engine_reader = create_engine(DATABASE_URL_READER, connect_args=SSL_ARGS)
SessionReader = sessionmaker(autocommit=False, autoflush=False, bind=engine_reader)

# マイグレーション用
engine = engine_writer
Base = declarative_base()

def get_db():
    """書き込み用セッション"""
    db = SessionWriter()
    try:
        yield db
    finally:
        db.close()

def get_db_reader():
    """読み込み用セッション（現在はWriterと同じエンドポイント）"""
    db = SessionReader()
    try:
        yield db
    finally:
        db.close()