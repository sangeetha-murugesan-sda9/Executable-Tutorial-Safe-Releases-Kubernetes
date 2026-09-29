FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && useradd -u 10001 app

ARG APP_FILE=app.py
ARG APP_VERSION=dev
COPY ${APP_FILE} app.py
ENV APP_VERSION=${APP_VERSION} PYTHONUNBUFFERED=1

USER app
EXPOSE 8080
CMD ["gunicorn", "-b", "0.0.0.0:8080", "-w", "2", "--threads", "4", "--graceful-timeout", "10", "--access-logfile", "-", "app:app"]
