import os

import psycopg2
import pytest

import app.app as app_module


@pytest.fixture
def postgres_client(monkeypatch):
    database_url = os.environ.get("TEST_DATABASE_URL")
    if not database_url:
        if os.environ.get("REQUIRE_TEST_DATABASE") == "1":
            pytest.fail("REQUIRE_TEST_DATABASE=1 but TEST_DATABASE_URL is not set")
        pytest.skip("Set TEST_DATABASE_URL to run PostgreSQL integration tests")

    def connect_to_test_database():
        return psycopg2.connect(database_url, connect_timeout=3)

    def reset_visits_table():
        connection = connect_to_test_database()
        try:
            with connection:
                with connection.cursor() as cursor:
                    cursor.execute("DROP TABLE IF EXISTS visits")
        finally:
            connection.close()

    try:
        reset_visits_table()
    except psycopg2.Error:
        pytest.fail("Could not connect to TEST_DATABASE_URL; check the test database and credentials")

    monkeypatch.setattr(app_module, "get_db_connection", connect_to_test_database)
    try:
        yield app_module.app.test_client()
    finally:
        reset_visits_table()


def test_api_status_checks_postgres(postgres_client):
    response = postgres_client.get("/api/status")

    assert response.status_code == 200
    assert response.json == {
        "application": "Taskboard demo",
        "api": "healthy",
        "database": "healthy",
    }


def test_visits_are_persisted_in_postgres(postgres_client):
    initial = postgres_client.get("/api/visits")
    recorded = postgres_client.post("/api/visits")
    after_write = postgres_client.get("/api/visits")

    assert initial.status_code == 200
    assert initial.json == {"total_visits": 0}
    assert recorded.status_code == 201
    assert recorded.json == {"total_visits": 1}
    assert after_write.status_code == 200
    assert after_write.json == {"total_visits": 1}
