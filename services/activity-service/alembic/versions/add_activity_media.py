# add_activity_media.py

"""add activity_media table

Revision ID: 004_add_activity_media
Revises: 003_add_status
Create Date: 2026-05-11
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "004_add_activity_media"
down_revision = "003_add_status"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "activity_media",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
        ),
        sa.Column(
            "activity_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("activities.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("url", sa.String(), nullable=False),
        sa.Column("type", sa.String(), nullable=False),
    )

    op.create_index(
        "ix_activity_media_activity_id",
        "activity_media",
        ["activity_id"],
    )


def downgrade():
    op.drop_index("ix_activity_media_activity_id", table_name="activity_media")
    op.drop_table("activity_media")