"""Ajouts de colonnes légers pour bases SQLite existantes (sans Alembic)."""

from sqlalchemy import inspect, text

from app.core.database import engine


def run_sqlite_migrations() -> None:
    insp = inspect(engine)
    with engine.connect() as conn:
        if insp.has_table("users"):
            cols = {c["name"] for c in insp.get_columns("users")}
            if "is_active" not in cols:
                conn.execute(
                    text(
                        "ALTER TABLE users ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT 1"
                    )
                )
                conn.commit()
            if "telephone" not in cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN telephone VARCHAR"))
                conn.commit()
            if "reset_code" not in cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN reset_code VARCHAR"))
                conn.commit()
            if "reset_code_expires_at" not in cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN reset_code_expires_at TIMESTAMP"))
                conn.commit()
        if insp.has_table("patients"):
            cols = {c["name"] for c in insp.get_columns("patients")}
            if "date_naissance" not in cols:
                conn.execute(text("ALTER TABLE patients ADD COLUMN date_naissance DATE"))
                conn.commit()
        if insp.has_table("images"):
            cols = {c["name"] for c in insp.get_columns("images")}
            if "body_zone_id" not in cols:
                conn.execute(text("ALTER TABLE images ADD COLUMN body_zone_id VARCHAR"))
                conn.commit()
            if "body_zone_label" not in cols:
                conn.execute(text("ALTER TABLE images ADD COLUMN body_zone_label VARCHAR"))
                conn.commit()
            if "symptoms_json" not in cols:
                conn.execute(text("ALTER TABLE images ADD COLUMN symptoms_json TEXT"))
                conn.commit()
        if insp.has_table("dermatologues"):
            cols = {c["name"] for c in insp.get_columns("dermatologues")}
            if "numero_rpps" not in cols:
                conn.execute(
                    text("ALTER TABLE dermatologues ADD COLUMN numero_rpps VARCHAR")
                )
                conn.commit()
        if insp.has_table("notifications"):
            cols = {c["name"] for c in insp.get_columns("notifications")}
            if "doctor_id" not in cols:
                conn.execute(
                    text("ALTER TABLE notifications ADD COLUMN doctor_id INTEGER")
                )
                conn.commit()
