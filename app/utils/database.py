import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "mysql://admin:password@localhost:3306/kazudb"
)

# pymysql→mysqlclientに変更（caching_sha2_password対応）
# DATABASE_URLのスキームをmysql+mysqldbに変更
DATABASE_URL = DATABASE_URL.replace("mysql+pymysql://", "mysql+mysqldb://")
DATABASE_URL = DATABASE_URL.replace("mysql://", "mysql+mysqldb://")

engine = create_engine(
    DATABASE_URL,
    connect_args={
        "ssl": {
            "ca": "/etc/ssl/certs/ca-certificates.crt"
        }
    }
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
