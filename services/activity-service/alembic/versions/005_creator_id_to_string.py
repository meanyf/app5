# 005_creator_id_to_string.py

"""creator_id to string

Revision ID: 005_creator_id_to_string
Revises: 004_add_activity_media
Create Date: 2026-05-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '005_creator_id_to_string'
down_revision = '004_add_activity_media'
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column(
        'activities',
        'creator_id',
        type_=sa.String(36),
        existing_type=UUID(as_uuid=True),
        postgresql_using='creator_id::text',
    )


def downgrade():
    op.alter_column(
        'activities',
        'creator_id',
        type_=UUID(as_uuid=True),
        existing_type=sa.String(36),
        postgresql_using='creator_id::uuid',
    )