import os
from contextlib import closing
from time import time

import psycopg2
from flask import Flask, jsonify
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["endpoint"],
)


def get_db_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connect_timeout=3,
    )


def ensure_visits_table(cursor):
    cursor.execute(
        """
        CREATE TABLE IF NOT EXISTS visits (
            id BIGSERIAL PRIMARY KEY,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
        """
    )


@app.before_request
def start_timer():
    from flask import request

    request.start_time = time()


@app.after_request
def record_request(response):
    from flask import request

    duration = time() - request.start_time
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.path).observe(duration)
    return response


@app.get("/health")
def health():
    return jsonify(status="healthy")


@app.get("/api/status")
def status():
    try:
        with closing(get_db_connection()) as connection:
            with connection:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
        return jsonify(application="Taskboard demo", api="healthy", database="healthy")
    except (KeyError, psycopg2.Error):
        return jsonify(application="Taskboard demo", api="healthy", database="unavailable"), 503


@app.get("/api/visits")
def get_visits():
    try:
        with closing(get_db_connection()) as connection:
            with connection:
                with connection.cursor() as cursor:
                    ensure_visits_table(cursor)
                    cursor.execute("SELECT COUNT(*) FROM visits")
                    total = cursor.fetchone()[0]
        return jsonify(total_visits=total)
    except (KeyError, psycopg2.Error):
        return jsonify(message="The visit counter is temporarily unavailable."), 503


@app.post("/api/visits")
def record_visit():
    try:
        with closing(get_db_connection()) as connection:
            with connection:
                with connection.cursor() as cursor:
                    ensure_visits_table(cursor)
                    cursor.execute("INSERT INTO visits DEFAULT VALUES")
                    cursor.execute("SELECT COUNT(*) FROM visits")
                    total = cursor.fetchone()[0]
        return jsonify(total_visits=total), 201
    except (KeyError, psycopg2.Error):
        return jsonify(message="The visit counter is temporarily unavailable."), 503


@app.get("/db-health")
def db_health():
    try:
        with closing(get_db_connection()) as connection:
            with connection:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1")
        return jsonify(database="healthy")
    except (KeyError, psycopg2.Error):
        return jsonify(database="unhealthy"), 503


@app.get("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
