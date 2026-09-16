import os
import psycopg2

from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, generate_latest
from prometheus_client import CONTENT_TYPE_LATEST
from time import time

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["endpoint"]
)


def get_db_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"]
    )


@app.before_request
def before_request():
    from flask import request
    request.start_time = time()


@app.after_request
def after_request(response):
    from flask import request

    duration = time() - request.start_time

    REQUEST_COUNT.labels(
        request.method,
        request.path,
        response.status_code
    ).inc()

    REQUEST_LATENCY.labels(request.path).observe(duration)

    return response


@app.route("/")
def home():

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            CREATE TABLE IF NOT EXISTS visits (
                id SERIAL PRIMARY KEY,
                message VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)

        cursor.execute(
            "INSERT INTO visits (message) VALUES (%s)",
            ("Hello from ECS!",)
        )

        cursor.execute("SELECT COUNT(*) FROM visits")
        count = cursor.fetchone()[0]

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({
            "application": "DevOps Demo API",
            "message": "Hello from AWS ECS!",
            "total_visits": count
        })

    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    })


@app.route("/db-health")
def db_health():

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()

        cursor.close()
        conn.close()

        return jsonify({
            "database": "healthy"
        })

    except Exception as e:

        return jsonify({
            "database": "unhealthy",
            "error": str(e)
        }), 500


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {
        "Content-Type": CONTENT_TYPE_LATEST
    }


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000
    )