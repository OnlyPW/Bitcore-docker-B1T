FROM debian:bookworm-slim

LABEL maintainer="OnlyPW"

ARG BIT_URL=https://github.com/bittoshimoto/Bit/releases/download/Bit.v3/bit.v3.tar.gz

ENV DEBIAN_FRONTEND=noninteractive \
    DATADIR=/data

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      tini \
      gosu \
      openssl \
      # Runtime-Libs (breit gefasst für Bitcoin-ähnliche Cores)
      libstdc++6 \
      libgcc-s1 \
      libevent-2.1-7 \
      libevent-pthreads-2.1-7 \
      libzmq5 \
      libminiupnpc17 \
      libssl3 \
      libsodium23 \
      libdb5.3 \
      libdb5.3++ \
      libboost-system1.74.0 \
      libboost-filesystem1.74.0 \
      libboost-thread1.74.0 \
      libboost-program-options1.74.0 \
      libboost-chrono1.74.0 \
    && rm -rf /var/lib/apt/lists/*

# Benutzer und Verzeichnisse
RUN groupadd -r bit && useradd -r -g bit -d ${DATADIR} -s /usr/sbin/nologin bit \
    && mkdir -p /opt/bit ${DATADIR} \
    && chown -R bit:bit ${DATADIR}

# Download und Installation der Binär
RUN set -euxo pipefail \
    && curl -L -o /tmp/bit.tar.gz "${BIT_URL}" \
    && mkdir -p /tmp/bit-extract \
    && tar -xzf /tmp/bit.tar.gz -C /tmp/bit-extract \
    && rm /tmp/bit.tar.gz \
    && BIN_DIR=$(find /tmp/bit-extract -type f -name "bitd" | head -n1 | xargs dirname) \
    && if [ -z "$BIN_DIR" ]; then BIN_DIR=/tmp/bit-extract; fi \
    && for f in bitd bit-cli bit-tx; do \
        if [ -f "${BIN_DIR}/${f}" ]; then install -m 0755 "${BIN_DIR}/${f}" /usr/local/bin/; fi; \
       done \
    && rm -rf /tmp/bit-extract

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/data"]

# 
# Standard-Ports (anpassbar via Compose/Run):
# - 8333: P2P
# - 8332: RPC
EXPOSE 8333 8332

ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]