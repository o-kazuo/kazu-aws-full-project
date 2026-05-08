from sqlalchemy import Column, String, Text, DateTime, Float
from sqlalchemy.sql import func
import uuid
from utils.database import Base

class AiResult(Base):
    __tablename__ = 'ai_results'

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(255), index=True, nullable=False)
    service = Column(String(50), nullable=False)
    input_s3_key = Column(String(500), nullable=True)
    result = Column(Text, nullable=True)
    status = Column(String(20), default="processing", nullable=False)
    processing_time = Column(Float, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "service": self.service,
            "input_s3_key": self.input_s3_key,
            "result": self.result,
            "status": self.status,
            "processing_time": self.processing_time,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
