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
