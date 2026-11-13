FROM nginx:1.30.6-alpine3.24
LABEL org.opencontainers.image.title="Portfolio Frontend" \
      org.opencontainers.image.description="Frontend container for the portfolio deployment"

RUN apk add --no-cache --upgrade libxslt

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html styles.css app.js /usr/share/nginx/html/

EXPOSE 80
