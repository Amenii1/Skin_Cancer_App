"""Ajouts de colonnes légers pour bases SQLite existantes (sans Alembic)."""

from sqlalchemy import inspect, text

from app.core.database import engine


def run_sqlite_migrations() -> None:
    if engine.dialect.name != "sqlite":
        return
    insp = inspect(engine)
    with engine.connect() as conn:
        if insp.has_table("users"):
            cols = {c["name"] for c in insp.get_columns("users")}
            if "telephone" not in cols:
                conn.execute(text("ALTER TABLE users ADD COLUMN telephone VARCHAR"))
                conn.commit()
        if insp.has_table("patients"):
            cols = {c["name"] for c in insp.get_columns("patients")}
            if "date_naissance" not in cols:
                conn.execute(text("ALTER TABLE patients ADD COLUMN date_naissance DATE"))
                conn.commit()
        if insp.has_table("dermatologues"):
            cols = {c["name"] for c in insp.get_columns("dermatologues")}
            if "numero_rpps" not in cols:
                conn.execute(
                    text("ALTER TABLE dermatologues ADD COLUMN numero_rpps VARCHAR")
                )
                conn.commit()
