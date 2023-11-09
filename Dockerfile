## 
FROM ghcr.io/cloudnative-pg/postgresql:15.4-18
# To install any package we need to be root
USER root
# We update the package list, install our package
# and clean up any cache from the package manager
RUN set -xe; \
	apt-get update; \
    apt-get install -y lsb-release wget; \
    echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list; \
    wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add - ; \
    apt-get update; \
	apt-get install -y --no-install-recommends \
		"timescaledb-2-postgresql-15='2.10.3*'" ; \
    apt-get remove -y lsb-release wget ; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Install timescaledb 2.x Extension
# RUN set -xe; \
#     apt-get update; \
#     apt-get install -y lsb-release wget; \
#     && echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list \
#     && wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add - \
#     && apt-get update \
#     && apt-get install -y timescaledb-2-postgresql-15='2.9.3*' \
#     && apt-get remove -y lsb-release wget \
#     && 	rm -fr /tmp/* \
#     && 	rm -rf /var/lib/apt/lists/*
# Change to the uid of postgres (26)
USER 26