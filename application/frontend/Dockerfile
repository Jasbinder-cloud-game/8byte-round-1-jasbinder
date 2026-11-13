FROM nginx:1.30.6-alpine3.24

RUN apk add --no-cache --upgrade libxslt

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html styles.css app.js /usr/share/nginx/html/

EXPOSE 80
