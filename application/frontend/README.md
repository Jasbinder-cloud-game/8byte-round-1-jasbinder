# Platform demo frontend

This static NGINX page displays the Flask API and PostgreSQL health and a persisted visit count. It sends same-origin requests to `/api/status` and `/api/visits`.

The ALB should send `/api/*` to the backend target group and all other paths to this frontend target group. NGINX serves `/health` for its target group health check.

## API contract

| Method | Path | Behavior |
| --- | --- | --- |
| `GET` | `/api/status` | Return API and database health. |
| `GET` | `/api/visits` | Return `{ "total_visits": number }`. |
| `POST` | `/api/visits` | Record a visit in PostgreSQL and return the updated total. |

Build the image from the repository root:

```sh
docker build -t platform-demo-frontend -f application/frontend/Dockerfile application/frontend
```
