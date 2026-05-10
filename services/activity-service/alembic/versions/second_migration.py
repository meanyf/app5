# second_migration.py

from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = "002_add_max_participants"
down_revision = "001_create_activities"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "activities",
        sa.Column("max_participants", sa.Integer(), nullable=True)
    )


def downgrade():
    op.drop_column("activities", "max_participants")