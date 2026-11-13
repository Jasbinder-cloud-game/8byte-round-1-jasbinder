FROM python:3.12-slim

WORKDIR /app

COPY app/requirements.txt .

RUN apt-get update \
    && apt-get install --only-upgrade -y --no-install-recommends zlib1g \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 5000

CMD ["python", "app.py"]