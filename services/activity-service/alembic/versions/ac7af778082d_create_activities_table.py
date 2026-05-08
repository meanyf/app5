# ac7af778082d_create_activities_table.py

"""create activities table

Revision ID: 001_create_activities
Revises:
Create Date: 2026-05-07

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from geoalchemy2 import Geography


# revision identifiers, used by Alembic.
revision = "001_create_activities"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # включаем PostGIS
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    op.create_table(
        "activities",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "type",
            sa.String(),
            nullable=False,
        ),

        sa.Column(
            "creator_id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
        ),

        sa.Column(
            "title",
            sa.String(),
            nullable=False,
        ),

        sa.Column(
            "description",
            sa.Text(),
            nullable=True,
        ),

        sa.Column(
            "location",
            Geography(geometry_type="POINT", srid=4326),
            nullable=False,
        ),

        sa.Column(
            "starts_at",
            sa.DateTime(),
            nullable=False,
        ),

        sa.Column(
            "expires_at",
            sa.DateTime(),
            nullable=False,
        ),
    )

    # spatial index
    op.create_index(
        "ix_activities_location",
        "activities",
        ["location"],
        postgresql_using="gist",
    )


def downgrade():
    op.drop_index("ix_activities_location", table_name="activities")
    op.drop_table("activities")