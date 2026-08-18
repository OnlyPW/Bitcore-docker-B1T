# syntax=docker/dockerfile:1

# Build-Quelle wählen:
#   SOURCE_BUILD=0 (Default): gepatchte Release-Binaries v4.0.0.0 aus OnlyPW/Bit-core laden
#   SOURCE_BUILD=1:           aus OnlyPW/Bit-core-Quellcode kompilieren (langsam)
# In docker-compose.yml via:  SOURCE_BUILD=1 docker compose build
# Mit docker direkt:          docker build --target bitcore-1 .
ARG SOURCE_BUILD=0
ARG BIT_URL=https://github.com/OnlyPW/Bit-core/releases/download/v4.0.0.0/Bit-v4.0.0.0.tar.gz
ARG BIT_SOURCE_URL=https://github.com/OnlyPW/Bit-core.git
ARG BIT_SOURCE_REF=main

# ---------------------------------------------------------------------------
# Stage: Quell-Kompilierung (nur gebaut, wenn bitcore-1 als Ziel ausgewaehlt)
# Reproduziert den Release-Build: Debian bookworm, System-Bibliotheken
# (Boost 1.74, BDB 5.3, OpenSSL 3, libevent 2.1) - identisch zum Original-Release
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS source-build
ARG BIT_SOURCE_URL
ARG BIT_SOURCE_REF
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libtool autotools-dev automake pkg-config bsdmainutils \
      ca-certificates curl python3 git \
      libssl-dev libevent-dev \
      libboost-filesystem1.74-dev libboost-program-options1.74-dev \
      libboost-thread1.74-dev libboost-chrono1.74-dev libboost-system1.74-dev \
      libboost-test1.74-dev \
      libdb5.3++-dev libminiupnpc-dev libzmq3-dev \
      qtbase5-dev qttools5-dev-tools protobuf-compiler libprotobuf-dev libqrencode-dev \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "${BIT_SOURCE_REF}" "${BIT_SOURCE_URL}" /tmp/bit-src
WORKDIR /tmp/bit-src
RUN ./autogen.sh \
    && ./configure --with-incompatible-bdb \
    && make -j"$(nproc)" \
    && mkdir -p /out \
    && cp -v src/bitd src/bit-cli src/bit-tx /out/ \
    && (cp -v src/qt/bit-qt /out/ || true)

# ---------------------------------------------------------------------------
# Stage: gemeinsame Laufzeit-Basis
# ---------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime-base

LABEL maintainer="OnlyPW"

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

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/data"]

#
# Standard-Ports (anpassbar via Compose/Run):
# - 33317: P2P  (Chain-Default, chainparams.cpp)
# - 45873: RPC  (Chain-Default, chainparamsbase.cpp)
EXPOSE 33317 45873

# ---------------------------------------------------------------------------
# Stage: bitcore-1 - Binaries aus dem Quellbuild uebernehmen
# ---------------------------------------------------------------------------
FROM runtime-base AS bitcore-1
COPY --from=source-build /out/bitd /usr/local/bin/bitd
COPY --from=source-build /out/bit-cli /usr/local/bin/bit-cli
COPY --from=source-build /out/bit-tx /usr/local/bin/bit-tx
RUN chmod 0755 /usr/local/bin/bitd /usr/local/bin/bit-cli /usr/local/bin/bit-tx
ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]

# ---------------------------------------------------------------------------
# Stage: bitcore-0 (Default) - gepatchte Release-Binaries herunterladen
# Muss die letzte Stage bleiben, damit ein einfaches `docker build .` den
# schnellen Download-Pfad verwendet.
# ---------------------------------------------------------------------------
FROM runtime-base AS bitcore-0
ARG BIT_URL

# Download und Installation der Binär
RUN set -euxo pipefail \
    && curl -L -o /tmp/bit.tar.gz "${BIT_URL}" \
    && mkdir -p /tmp/bit-extract \
    && tar -xzf /tmp/bit.tar.gz -C /tmp/bit-extract \
    && rm /tmp/bit.tar.gz \
    && BIN_DIR=$(find /tmp/bit-extract -type f -name "bitd" | head -n1 | xargs dirname) \
    && if [ -z "$BIN_DIR" ]; then BIN_DIR=/tmp/bit-extract; fi \
    && for f in bitd bit-cli bit-tx bit-qt; do \
        if [ -f "${BIN_DIR}/${f}" ]; then install -m 0755 "${BIN_DIR}/${f}" /usr/local/bin/; fi; \
       done \
    && rm -rf /tmp/bit-extract

ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
