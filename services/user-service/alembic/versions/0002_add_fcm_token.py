# 0002_add_fcm_token.py

"""add fcm_token to users

Revision ID: 0002_add_fcm_token
Revises: 0001_create_users
Create Date: 2026-05-24
"""

from alembic import op
import sqlalchemy as sa

revision = "0002_add_fcm_token"
down_revision = "0001_create_users"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("fcm_token", sa.String(500), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "fcm_token")