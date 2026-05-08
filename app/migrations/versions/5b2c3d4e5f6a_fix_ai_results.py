"""fix_ai_results

Revision ID: 5b2c3d4e5f6a
Revises: 3c344c79aa1c
Create Date: 2026-05-08

"""
from alembic import op
import sqlalchemy as sa

revision = '5b2c3d4e5f6a'
down_revision = '3c344c79aa1c'
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.execute("DROP TABLE IF EXISTS ai_results")
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
        sa.Column('updated_at', sa.DateTime, server_default=sa.func.now()),
    )

def downgrade() -> None:
    op.drop_table('ai_results')
