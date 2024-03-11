## 
FROM postgres:16.2-alpine3.19
# To install any package we need to be root
USER root
COPY ./x86_64 /tmp/
RUN ls -lah /tmp/
# We update the package list, install our package , # Install timescaledb 2.x Extension
# and clean up any cache from the package manager
RUN set -xe; \
    sed -i 's|v3\.\d*|edge|' /etc/apk/repositories; \
	apk update; \
    apk add postgresql-pgvector; \
    apk add postgresql-timescaledb; \
    apk add barman --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/; \
    apk add --allow-untrusted /tmp/pgaudit-16.0-r1.apk; \
    apk add --allow-untrusted /tmp/pg-failover-slots-1.0.1-r1.apk;
# Change the uid of postgres to 26
RUN apk add --no-cache shadow \
	&& usermod -u 26 postgres \
	&& apk del shadow
USER 26
