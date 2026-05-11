# add_status.py

"""add status to activities

Revision ID: 003_add_status
Revises: 002_add_max_participants
Create Date: 2026-05-10
"""

from alembic import op
import sqlalchemy as sa

revision = "003_add_status"
down_revision = "002_add_max_participants"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "activities",
        sa.Column(
            "status",
            sa.String(),
            nullable=False,
            server_default="pending",
        ),
    )


def downgrade():
    op.drop_column("activities", "status")