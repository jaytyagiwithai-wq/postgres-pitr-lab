FROM debian:bookworm-slim AS walg-downloader

ARG WALG_VERSION=3.0.8
ARG WALG_SHA256=f30544c5ce93cf83b87578e3c4a2e9c0e0ffc3d160ef89ecddaf75f397d98deb

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
    && curl --fail --silent --show-error --location \
       "https://github.com/wal-g/wal-g/releases/download/v${WALG_VERSION}/wal-g-pg-22.04-amd64" \
       --output /wal-g \
    && echo "${WALG_SHA256}  /wal-g" | sha256sum --check \
    && chmod 0755 /wal-g


FROM postgres:16.15-bookworm

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=walg-downloader /wal-g /usr/local/bin/wal-g

RUN wal-g --version
