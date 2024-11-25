# First stage: Build stage
FROM postgres:17.2-alpine AS build

# Install build dependencies
RUN apk add -U --no-cache -t .build-deps1 \
    $DOCKER_PG_LLVM_DEPS \
    git \
    build-base \
    openssl-dev \
    krb5-dev

# Build and install pgaudit
WORKDIR /pgaudit
RUN git clone https://github.com/pgaudit/pgaudit --branch REL_17_STABLE . \
    && make install USE_PGXS=1 PG_CONFIG=/usr/local/bin/pg_config

# Build and install pg_failover_slots
WORKDIR /pg_failover_slots
RUN git clone https://github.com/EnterpriseDB/pg_failover_slots --branch v1.1.0 . \
    && make install




# # Build TSDB-toolkit
# RUN TS_TOOLKIT_VERSION=1.18.0 \
#     && curl https://sh.rustup.rs -sSf | sh -s -- -y --profile=minimal -c rustfmt \
#     && export PATH=$PATH:~/.cargo/bin/ \
#     && cargo install --version '=0.10.2' --force cargo-pgrx \
#     && cargo pgrx init --pg16 pg_config \
#     && mkdir -p /tsdb-toolkit && cd /tsdb-toolkit \
#     && git clone https://github.com/timescale/timescaledb-toolkit \
#     && cd timescaledb-toolkit \
#     && git checkout ${TS_TOOLKIT_VERSION} \
#     && cd extension \
#     && cargo pgrx install --release \
#     && cargo run --manifest-path ../tools/post-install/Cargo.toml -- pg_config


# Timescaledb alpine image (pre-build)
FROM timescale/timescaledb:2.17.2-pg17 AS timescaledb-alpine

# Create the final container
FROM timescale/timescaledb:2.17.2-pg17
# To install any package we need to be root user
USER root
# barman-cloud-backup will remove this from container
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk add -U --no-cache -t python3-dev libffi-dev \
    openssl-dev gcc musl-dev py3-pip barman
# Copy timescaledb 
COPY --from=timescaledb-alpine /usr/local/lib/postgresql/timescaledb-*.so /usr/local/lib/postgresql/
COPY --from=timescaledb-alpine /usr/local/share/postgresql/extension/timescaledb--*.sql /usr/local/share/postgresql/extension/

# Copy the compiled pgaudit files from the build stage
COPY --from=build /usr/local/lib/postgresql/pgaudit.so /usr/local/lib/postgresql/pgaudit.so
COPY --from=build /usr/local/lib/postgresql/bitcode/pgaudit /usr/local/lib/postgresql/bitcode/pgaudit
COPY --from=build /usr/local/lib/postgresql/bitcode/pgaudit.index.bc /usr/local/lib/postgresql/bitcode/pgaudit.index.bc
COPY --from=build /usr/local/share/postgresql/extension/pgaudit.control /usr/local/share/postgresql/extension/pgaudit.control
COPY --from=build /usr/local/share/postgresql/extension/pgaudit--17.0.sql /usr/local/share/postgresql/extension/pgaudit--17.0.sql

# Copy the compiled pg_failover_slots files from the build stage
COPY --from=build /usr/local/lib/postgresql/pg_failover_slots.so /usr/local/lib/postgresql/pg_failover_slots.so
COPY --from=build /usr/local/lib/postgresql/bitcode/pg_failover_slots /usr/local/lib/postgresql/bitcode/pg_failover_slots
COPY --from=build /usr/local/lib/postgresql/bitcode/pg_failover_slots.index.bc /usr/local/lib/postgresql/bitcode/pg_failover_slots.index.bc

# Change the uid of postgres to 70
# https://github.com/docker-library/postgres/blob/172544062d1031004b241e917f5f3f9dfebc0df5/17/alpine3.20/Dockerfile
USER 70