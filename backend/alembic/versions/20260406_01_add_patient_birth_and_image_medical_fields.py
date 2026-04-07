"""Add patient birth date and image medical record fields.

Revision ID: 20260406_01
Revises:
Create Date: 2026-04-06
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "20260406_01"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    patient_columns = {col["name"] for col in inspector.get_columns("patients")}
    image_columns = {col["name"] for col in inspector.get_columns("images")}
    image_indexes = {idx["name"] for idx in inspector.get_indexes("images")}

    if "date_naissance" not in patient_columns:
        op.add_column("patients", sa.Column("date_naissance", sa.Date(), nullable=True))

    if "body_zone_id" not in image_columns:
        op.add_column("images", sa.Column("body_zone_id", sa.String(), nullable=True))
    if "body_zone_label" not in image_columns:
        op.add_column("images", sa.Column("body_zone_label", sa.String(), nullable=True))
    if "symptoms_json" not in image_columns:
        op.add_column("images", sa.Column("symptoms_json", sa.Text(), nullable=True))

    if "ix_images_body_zone_id" not in image_indexes and "body_zone_id" in {
        col["name"] for col in sa.inspect(bind).get_columns("images")
    }:
        op.create_index("ix_images_body_zone_id", "images", ["body_zone_id"], unique=False)


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    image_columns = {col["name"] for col in inspector.get_columns("images")}
    image_indexes = {idx["name"] for idx in inspector.get_indexes("images")}
    patient_columns = {col["name"] for col in inspector.get_columns("patients")}

    if "ix_images_body_zone_id" in image_indexes:
        op.drop_index("ix_images_body_zone_id", table_name="images")

    if "symptoms_json" in image_columns:
        op.drop_column("images", "symptoms_json")
    if "body_zone_label" in image_columns:
        op.drop_column("images", "body_zone_label")
    if "body_zone_id" in image_columns:
        op.drop_column("images", "body_zone_id")

    if "date_naissance" in patient_columns:
        op.drop_column("patients", "date_naissance")
