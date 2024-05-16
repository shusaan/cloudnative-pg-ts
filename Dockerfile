# First stage: Build stage
FROM postgres:16.3-alpine3.19 AS build

# Install necessary packages
RUN apk update && apk add -U --no-cache -t .build-deps1 \
    git \
    build-base \
    openssl-dev \
    krb5-dev \
    dpkg-dev \
    dpkg \
    gcc \
    libc-dev \
    make \
    cmake \
    util-linux-dev \
    curl \
    musl-dev \
    coreutils \
    readline-dev \
    zlib-dev \
    flex-dev \
    libxml2-dev \
    libxslt-dev \
    libxml2-utils \
    pkgconf \
    cargo \
    clang \
    python3 \
    python3-dev \
    py3-pip

# Build and install pgaudit
RUN mkdir /pgaudit && cd /pgaudit \
    && git clone https://github.com/pgaudit/pgaudit --branch REL_16_STABLE . \
    && make install USE_PGXS=1 PG_CONFIG=/usr/local/bin/pg_config

# Build and install pg_failover_slots
RUN mkdir /pg_failover_slots && cd /pg_failover_slots \
    && git clone https://github.com/EnterpriseDB/pg_failover_slots --branch v1.0.1 . \
    && make install

# Build and install pgvector
RUN mkdir /pgvector && cd /pgvector \
    && git clone https://github.com/pgvector/pgvector --branch v0.6.0 . \
    && make install OPTFLAGS=""

# Build and install barman
RUN python3 -m venv /app/venv \
    && PATH="/app/venv/bin:$PATH" \
    && pip install --no-cache-dir 'barman[cloud,azure,snappy,google]'

# Build Timescaledb
RUN TS_VERSION=2.15.0 \
    && mkdir -p /tsdb && cd /tsdb \
    && git clone https://github.com/timescale/timescaledb \
    && cd timescaledb \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker" \
    && cd build \
    && make install

# Build TSDB-toolkit
RUN TS_TOOLKIT_VERSION=1.18.0 \
    && curl https://sh.rustup.rs -sSf | sh -s -- -y --profile=minimal -c rustfmt \
    && export PATH=$PATH:~/.cargo/bin/ \
    && cargo install --version '=0.10.2' --force cargo-pgrx \
    && cargo pgrx init --pg16 pg_config \
    && mkdir -p /tsdb-toolkit && cd /tsdb-toolkit \
    && git clone https://github.com/timescale/timescaledb-toolkit \
    && cd timescaledb-toolkit \
    && git checkout ${TS_TOOLKIT_VERSION} \
    && cd extension \
    && cargo pgrx install --release \
    && cargo run --manifest-path ../tools/post-install/Cargo.toml -- pg_config


# Second stage: Runtime stage
FROM postgres:16.3-alpine3.19
USER root

# Copy necessary files from build stage to runtime stage
COPY --from=build /usr/local/share/postgresql/extension/* /usr/local/share/postgresql/extension/
COPY --from=build /usr/local/lib/postgresql/* /usr/local/lib/postgresql/
COPY --from=build /app/venv/* /app/barman/
ENV PATH="/app/barman/bin:$PATH"

USER 26