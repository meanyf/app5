# 0003_add_description.py

"""add description to users

Revision ID: 0003_add_description
Revises: 0002_add_fcm_token
Create Date: 2026-06-01
"""

from alembic import op
import sqlalchemy as sa

revision = "0003_add_description"
down_revision = "0002_add_fcm_token"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("description", sa.String(1000), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "description")