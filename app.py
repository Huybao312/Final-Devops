from __future__ import annotations

import os
import sqlite3
from contextlib import closing
from pathlib import Path

from flask import Flask, abort, g, jsonify, redirect, render_template, request, url_for


BASE_DIR = Path(__file__).resolve().parent
DATABASE = Path(os.environ.get("TODO_DATABASE", BASE_DIR / "todo.db"))

app = Flask(__name__)
app.config["DATABASE"] = DATABASE


def get_db() -> sqlite3.Connection:
    """Return one SQLite connection for the current request."""
    if "db" not in g:
        g.db = sqlite3.connect(app.config["DATABASE"])
        g.db.row_factory = sqlite3.Row
    return g.db


def init_db() -> None:
    """Create the tasks table if this is a fresh installation."""
    app.config["DATABASE"].parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(app.config["DATABASE"])) as db:
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                completed INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
            """
        )
        db.commit()


@app.teardown_appcontext
def close_db(_error: BaseException | None = None) -> None:
    db = g.pop("db", None)
    if db is not None:
        db.close()


@app.get("/")
def index():
    tasks = get_db().execute(
        "SELECT id, title, description, completed, created_at "
        "FROM tasks ORDER BY completed ASC, id DESC"
    ).fetchall()
    return render_template("index.html", tasks=tasks)


@app.post("/tasks")
def create_task():
    title = request.form.get("title", "").strip()
    description = request.form.get("description", "").strip()
    if not title:
        return redirect(url_for("index", error="Task title is required."))

    db = get_db()
    db.execute("INSERT INTO tasks (title, description) VALUES (?, ?)", (title, description))
    db.commit()
    return redirect(url_for("index"))


@app.post("/tasks/<int:task_id>/edit")
def edit_task(task_id: int):
    title = request.form.get("title", "").strip()
    description = request.form.get("description", "").strip()
    if not title:
        return redirect(url_for("index", error="Task title is required."))

    db = get_db()
    result = db.execute(
        "UPDATE tasks SET title = ?, description = ? WHERE id = ?",
        (title, description, task_id),
    )
    if result.rowcount == 0:
        abort(404)
    db.commit()
    return redirect(url_for("index"))


@app.post("/tasks/<int:task_id>/toggle")
def toggle_task(task_id: int):
    db = get_db()
    result = db.execute(
        "UPDATE tasks SET completed = CASE completed WHEN 1 THEN 0 ELSE 1 END WHERE id = ?",
        (task_id,),
    )
    if result.rowcount == 0:
        abort(404)
    db.commit()
    return redirect(url_for("index"))


@app.post("/tasks/<int:task_id>/delete")
def delete_task(task_id: int):
    db = get_db()
    result = db.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
    if result.rowcount == 0:
        abort(404)
    db.commit()
    return redirect(url_for("index"))


@app.get("/health")
def health():
    try:
        get_db().execute("SELECT 1").fetchone()
    except sqlite3.Error:
        return jsonify(status="unhealthy"), 503
    return jsonify(status="healthy"), 200


init_db()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
