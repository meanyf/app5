# 0001_create_user_auth.py

"""create user_auth table

Revision ID: 0001_create_user_auth
Revises:
Create Date: 2025-05-13
"""

from alembic import op
import sqlalchemy as sa

revision = "0001_create_user_auth"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "user_auth",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("phone"),
    )
    op.create_index("ix_user_auth_phone", "user_auth", ["phone"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_user_auth_phone", table_name="user_auth")
    op.drop_table("user_auth")