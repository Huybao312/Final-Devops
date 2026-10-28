from __future__ import annotations

import os

import psycopg
from flask import Flask, abort, g, jsonify, redirect, render_template, request, url_for
from psycopg.rows import dict_row
from werkzeug.middleware.proxy_fix import ProxyFix

DATABASE_URL = os.environ.get("DATABASE_URL", "").strip()
if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL is not set. Create /etc/todo-task-manager.env from "
        "deploy/todo-task-manager.env.example (or run scripts/setup-db.sh)."
    )

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)


def get_db() -> psycopg.Connection:
    """Return one PostgreSQL connection for the current request."""
    if "db" not in g:
        g.db = psycopg.connect(DATABASE_URL, row_factory=dict_row)
    return g.db


@app.teardown_appcontext
def close_db(_error: BaseException | None = None) -> None:
    db = g.pop("db", None)
    if db is not None:
        db.close()


@app.get("/")
def index():
    tasks = get_db().execute(
        "SELECT id, title, description, completed, created_at "
        "FROM tasks ORDER BY completed ASC, created_at DESC, id DESC"
    ).fetchall()
    return render_template("index.html", tasks=tasks)


@app.post("/tasks")
def create_task():
    title = request.form.get("title", "").strip()
    description = request.form.get("description", "").strip()
    if not title:
        return redirect(url_for("index", error="Task title is required."))

    db = get_db()
    db.execute(
        "INSERT INTO tasks (title, description) VALUES (%s, %s)",
        (title, description),
    )
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
        "UPDATE tasks SET title = %s, description = %s WHERE id = %s",
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
        "UPDATE tasks SET completed = NOT completed WHERE id = %s",
        (task_id,),
    )
    if result.rowcount == 0:
        abort(404)
    db.commit()
    return redirect(url_for("index"))


@app.post("/tasks/<int:task_id>/delete")
def delete_task(task_id: int):
    db = get_db()
    result = db.execute("DELETE FROM tasks WHERE id = %s", (task_id,))
    if result.rowcount == 0:
        abort(404)
    db.commit()
    return redirect(url_for("index"))


@app.get("/health")
def health():
    try:
        get_db().execute("SELECT 1").fetchone()
    except psycopg.Error:
        return jsonify(status="unhealthy"), 503
    return jsonify(status="healthy"), 200


@app.get("/version")
def version():
    return jsonify(version=os.environ.get("APP_VERSION", "local")), 200


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000)
