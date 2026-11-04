FROM alpine:3
RUN apk add --no-cache unbound dnssec-root
USER unbound
ENTRYPOINT ["unbound", "-d", "-c", "/etc/unbound/unbound.conf"]
