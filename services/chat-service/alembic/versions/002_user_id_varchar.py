# 002_user_id_varchar.py

"""change user_id to varchar

Revision ID: 002_user_id_varchar
Revises: 001_create_comments_table
Create Date: 2026-05-20
"""

from alembic import op
import sqlalchemy as sa

revision = "002_user_id_varchar"
down_revision = "001_create_comments"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.alter_column(
        "comments",
        "user_id",
        type_=sa.String(36),
        postgresql_using="user_id::varchar(36)",
    )


def downgrade() -> None:
    op.alter_column(
        "comments",
        "user_id",
        type_=sa.UUID(),
        postgresql_using="user_id::uuid",
    )