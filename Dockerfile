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
RUN useradd --system --uid 10001 --home-dir /app --no-create-home appuser
USER appuser
EXPOSE 5000
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5000", "--no-control-socket", "--access-logfile", "-", "--error-logfile", "-", "app:app"]
