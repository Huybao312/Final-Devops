FROM python:3.12-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN python -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
ARG APP_VERSION=local
ENV APP_VERSION=${APP_VERSION} PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/opt/venv/bin:${PATH}"
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY app.py ./
COPY templates ./templates
RUN useradd --uid 10001 --user-group --home-dir /app --no-create-home --shell /usr/sbin/nologin appuser
USER appuser
EXPOSE 5000
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5000", "--no-control-socket", "--access-logfile", "-", "--capture-output", "--error-logfile", "-", "app:app"]
