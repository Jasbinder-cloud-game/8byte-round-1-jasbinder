# Platform demo backend

The Flask API provides health checks, Prometheus metrics, and a PostgreSQL-backed visit counter used by the NGINX frontend.

## Routes

- `GET /health` — container health check; does not depend on PostgreSQL.
- `GET /api/status` — API and database status.
- `GET /api/visits` — current persisted visit count.
- `POST /api/visits` — record a visit and return the new count.
- `GET /db-health` — PostgreSQL connectivity check.
- `GET /metrics` — Prometheus request counters and latency histogram.

Configure `DB_HOST`, `DB_NAME`, `DB_USER`, and `DB_PASSWORD`; `DB_PORT` defaults to `5432`. Do not commit database credentials. In AWS, inject the password from Secrets Manager through the ECS task definition.

Build the image from the repository root:

```sh
docker build -t platform-demo-backend -f application/devops-demo/Dockerfile application/devops-demo
```

## Validate locally

Install the application and test dependencies, then run the unit tests from this directory:

```sh
python -m pip install -r requirements-dev.txt
python -m pytest -q
```

The PostgreSQL integration tests are skipped unless `TEST_DATABASE_URL` is set. Use a disposable local database only; the tests drop and recreate the `visits` table in that database. For example, start a local PostgreSQL container in one terminal:

```sh
docker run --rm --name taskboard-test-db \
  -e POSTGRES_DB=taskboard_test \
  -e POSTGRES_USER=taskboard_test \
  -e POSTGRES_PASSWORD=test-only-password \
  -p 5432:5432 postgres:17-alpine
```

In a second terminal, from this directory, run:

```sh
TEST_DATABASE_URL=postgresql://taskboard_test:test-only-password@localhost:5432/taskboard_test \
  python -m pytest -q
```

Stop the database container with `Ctrl-C` when the tests finish. Never point `TEST_DATABASE_URL` at a production or shared database.
