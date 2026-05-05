from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func
from utils.database import Base

class AiResult(Base):
    __tablename__ = 'ai_results'

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    service_type = Column(String(50))
    input_data = Column(Text)
    output_data = Column(Text)
    created_at = Column(DateTime, server_default=func.now())