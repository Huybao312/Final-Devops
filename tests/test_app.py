import os
import uuid
from pathlib import Path

import psycopg
import pytest

if not os.environ.get("DATABASE_URL"):
    pytest.skip("Set DATABASE_URL to run PostgreSQL integration tests", allow_module_level=True)

from app import app  # noqa: E402


@pytest.fixture(scope="module", autouse=True)
def schema():
    sql = (Path(__file__).resolve().parents[1] / "db/schema.sql").read_text()
    with psycopg.connect(os.environ["DATABASE_URL"]) as db:
        db.execute(sql)


def test_health_and_crud():
    with psycopg.connect(os.environ["DATABASE_URL"]) as db:
        open_before = db.execute("SELECT count(*) FROM tasks WHERE NOT completed").fetchone()[0]
    title = f"ci-{uuid.uuid4().hex}"
    with app.test_client() as client:
        assert client.get("/health").json == {"status": "healthy"}
        response = client.post("/tasks", data={"title": title, "description": "created"})
        assert response.status_code == 302
        page = client.get("/").data
        assert title.encode() in page
        assert f"Open tasks: {open_before + 1}".encode() in page

        with psycopg.connect(os.environ["DATABASE_URL"]) as db:
            task_id, description, completed = db.execute(
                "SELECT id, description, completed FROM tasks WHERE title = %s", (title,)
            ).fetchone()
            assert (description, completed) == ("created", False)

        try:
            assert client.post(
                f"/tasks/{task_id}/edit",
                data={"title": title, "description": "edited"},
            ).status_code == 302
            assert client.post(f"/tasks/{task_id}/toggle").status_code == 302
            page = client.get("/").data
            assert f"Open tasks: {open_before}".encode() in page
            with psycopg.connect(os.environ["DATABASE_URL"]) as db:
                assert db.execute(
                    "SELECT description, completed FROM tasks WHERE id = %s", (task_id,)
                ).fetchone() == ("edited", True)
            assert client.post(f"/tasks/{task_id}/delete").status_code == 302
            assert title.encode() not in client.get("/").data
            assert client.post(f"/tasks/{task_id}/toggle").status_code == 404
        finally:
            with psycopg.connect(os.environ["DATABASE_URL"]) as db:
                db.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
