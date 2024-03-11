## 
FROM postgres:16.2-alpine3.19
# To install any package we need to be root
USER root
# We update the package list, install our package , # Install timescaledb 2.x Extension
# and clean up any cache from the package manager
RUN set -xe; \
    sed -i 's|v3\.\d*|edge|' /etc/apk/repositories; \
	apk update; \
    apk add postgresql-pgvector; \
    apk add postgresql-timescaledb; \
    apk add barman --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/; \
    apk add --allow-untrusted x86_64/pgaudit-16.0-r1.apk; \
    apk add --allow-untrusted x86_64/pg-failover-slots-1.0.1-r1.apk;
USER 26