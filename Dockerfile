# First step is to build the the extension
FROM debian:bullseye-slim as builder

RUN set -xe ;\
    apt update && apt install curl wget lsb-release gnupg2 -y ;\
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y ;\
    export PATH=$PATH:~/.cargo/bin/ && cargo --help ; \
    sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' ;\
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - ;\
    apt-get update ;\
	apt-get install -y make gcc pkg-config clang postgresql-server-dev-16 libssl-dev git; \
	cargo install --version '=0.10.2' --force cargo-pgrx; \
	cargo pgrx init --pg16 pg_config; \
	git clone https://github.com/timescale/timescaledb-toolkit && \
	cd timescaledb-toolkit/extension; \
	cargo pgrx install --release && \
	cargo run --manifest-path ../tools/post-install/Cargo.toml -- pg_config; \
	ls -lah /usr/share/postgresql/16/ && ls -lah /usr/share/postgresql/16/extension/ && ls -lah /usr/lib/postgresql/16/lib/


# FROM ghcr.io/cloudnative-pg/postgresql:16.2
# # To install any package we need to be root
# USER root
# # But this time we copy the .so file from the build process
# COPY --from=builder /tmp/timescaledb-toolkit/pg_crash.so /usr/lib/postgresql/16/lib/
# # We update the package list, install our package , # Install timescaledb 2.x Extension
# # and clean up any cache from the package manager
# RUN set -xe; \
# 	apt-get update; \
#     apt-get install -y lsb-release wget; \
#     echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list; \
#     wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add - ; \
#     apt-get update; \
# 	apt-get install -y --no-install-recommends \
#         timescaledb-2-postgresql-16='2.14.2*' timescaledb-2-loader-postgresql-16='2.14.2*'; \
#     apt-get remove -y lsb-release wget ; \
# 	rm -fr /tmp/* ; \
# 	rm -rf /var/lib/apt/lists/*;
# USER 26