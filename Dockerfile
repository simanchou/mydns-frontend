FROM alpine:3.12.2

LABEL maintainer="Siman Chou <simanchou@gmail.com> https://github.com/simanchou"

RUN apk update && apk add --no-cache supervisor nginx \
    && mkdir /var/log/coredns \
    # forward nginx request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log 

WORKDIR /mydns

COPY dist /var/www/html
COPY backend_server/nginx.conf /etc/nginx/nginx.conf
COPY backend_server/coredns coredns
COPY backend_server/supervisord.conf /etc/supervisord.conf
COPY backend_server/docker-entrypoint.sh docker-entrypoint.sh

ENTRYPOINT ["/mydns/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
