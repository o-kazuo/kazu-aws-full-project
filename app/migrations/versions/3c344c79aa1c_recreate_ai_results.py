"""recreate_ai_results

Revision ID: 3c344c79aa1c
Revises: 
Create Date: 2026-05-08

"""
from alembic import op
import sqlalchemy as sa

revision = '3c344c79aa1c'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 既存テーブルを削除して再作成
    op.drop_table('ai_results')
    op.create_table(
        'ai_results',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('user_id', sa.String(255), nullable=False, index=True),
        sa.Column('service', sa.String(50), nullable=False),
        sa.Column('input_s3_key', sa.String(500), nullable=True),
        sa.Column('result', sa.Text, nullable=True),
        sa.Column('status', sa.String(20), nullable=False, server_default='processing'),
        sa.Column('processing_time', sa.Float, nullable=True),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now(), onupdate=sa.func.now()),
    )

def downgrade() -> None:
    op.drop_table('ai_results')
    op.create_table(
        'ai_results',
        sa.Column('id', sa.Integer, primary_key=True, autoincrement=True),
        sa.Column('user_id', sa.Integer, index=True),
        sa.Column('service_type', sa.String(50)),
        sa.Column('input_data', sa.Text),
        sa.Column('output_data', sa.Text),
        sa.Column('created_at', sa.DateTime, server_default=sa.func.now()),
    )
