import os
import socket

import redis
from flask import Flask
from werkzeug.exceptions import HTTPException

VERSION = os.getenv("APP_VERSION", "dev")
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
HOSTNAME = socket.gethostname()

app = Flask(__name__)

# short timeouts, the readiness probe gives up after 1s anyway
db = redis.Redis(host=REDIS_HOST, port=6379, socket_connect_timeout=0.5, socket_timeout=0.5)


@app.get("/")
def index():
    hits = db.incr("hits")
    return f"version={VERSION} pod={HOSTNAME} hits={hits}\n"


@app.get("/healthz")
def healthz():
    try:
        db.ping()
    except redis.RedisError as e:
        return f"version={VERSION} redis=unreachable host={REDIS_HOST} error={type(e).__name__}\n", 503
    return f"version={VERSION} redis=ok\n"


@app.errorhandler(Exception)
def handle_error(e):
    if isinstance(e, HTTPException):
        return e
    app.logger.exception(e)
    # keep the version in error responses too, so we can see which release breaks
    return f"version={VERSION} pod={HOSTNAME} error={type(e).__name__}\n", 500
