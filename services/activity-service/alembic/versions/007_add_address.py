# 007_add_address.py

revision = '007'
down_revision = '006'
branch_labels = None
depends_on = None

from alembic import op
import sqlalchemy as sa


def upgrade():
    op.add_column('activities', sa.Column('address', sa.String(), nullable=True))


def downgrade():
    op.drop_column('activities', 'address')