import psycopg2
import pytest

import app.app as app_module


@pytest.fixture
def client():
    return app_module.app.test_client()


def test_health_is_independent_of_database(client, monkeypatch):
    def unexpected_database_call():
        raise AssertionError("/health must not connect to PostgreSQL")

    monkeypatch.setattr(app_module, "get_db_connection", unexpected_database_call)

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json == {"status": "healthy"}


def test_metrics_endpoint_returns_prometheus_content(client):
    response = client.get("/metrics")

    assert response.status_code == 200
    assert response.mimetype == "text/plain"
    assert response.data


@pytest.mark.parametrize("path", ["/api/status", "/api/visits", "/db-health"])
def test_database_routes_return_service_unavailable_on_connection_error(
    client, monkeypatch, path
):
    def fail_connection():
        raise psycopg2.OperationalError("simulated database outage")

    monkeypatch.setattr(app_module, "get_db_connection", fail_connection)

    response = client.get(path)

    assert response.status_code == 503
