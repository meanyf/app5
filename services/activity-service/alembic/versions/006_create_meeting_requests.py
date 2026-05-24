# 006_create_meeting_requests.py

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = '006'
down_revision = '005_creator_id_to_string'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'meeting_requests',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('activity_id', UUID(as_uuid=True), sa.ForeignKey('activities.id'), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('status', sa.String(), nullable=False, server_default='pending'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
    )

def downgrade():
    op.drop_table('meeting_requests')