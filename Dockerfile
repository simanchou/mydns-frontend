FROM alpine:3.12.2

LABEL maintainer="Siman Chou <simanchou@gmail.com> https://github.com/simanchou"

RUN apk update && apk add --no-cache supervisor nginx \
    && mkdir /var/log/coredns \
    && mkdir /mydns 

COPY dist /var/www/html
COPY backend_server/nginx.conf /etc/nginx/nginx.conf
COPY backend_server/coredns /mydns/coredns
COPY backend_server/Corefile /mydns/Corefile
COPY backend_server/supervisord.conf /etc/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
