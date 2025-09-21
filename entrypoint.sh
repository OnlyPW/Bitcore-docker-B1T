#!/usr/bin/env bash
set -euo pipefail

# Standardwerte
DATADIR=${DATADIR:-/data}
CONF_FILE="${DATADIR}/bit.conf"
CONFIG_TEMPLATE="/config/bit.conf"
USER_ID=${PUID:-1000}
GROUP_ID=${PGID:-1000}

# Benutzerumschaltung vorbereiten
if ! id -u bit >/dev/null 2>&1; then
  groupadd -g "$GROUP_ID" bit || true
  useradd -u "$USER_ID" -g "$GROUP_ID" -d "$DATADIR" -s /usr/sbin/nologin bit || true
fi

mkdir -p "$DATADIR"
chown -R "$USER_ID":"$GROUP_ID" "$DATADIR"

# Config erzeugen oder aktualisieren
if [ ! -f "$CONF_FILE" ] || [ "$CONF_FILE" -ot "$CONFIG_TEMPLATE" ]; then
  if [ -f "$CONFIG_TEMPLATE" ]; then
    echo "Kopiere Konfigurationsvorlage von $CONFIG_TEMPLATE nach $CONF_FILE"
    cp "$CONFIG_TEMPLATE" "$CONF_FILE"
    
    # Ersetze Platzhalter mit Umgebungsvariablen
    RPC_USER=${RPC_USER:-user}
    RPC_PASSWORD=${RPC_PASSWORD:-$(openssl rand -hex 16)}
    RPC_ALLOW_IP=${RPC_ALLOW_IP:-0.0.0.0/0}
    NETWORK=${NETWORK:-mainnet}
    
    # Erstelle neue Konfiguration mit Umgebungsvariablen
    cat > "$CONF_FILE" <<EOF
# Bit Core Configuration
# Generated from template with environment variables

# Network settings
server=1
daemon=0
txindex=1
addressindex=1
timestampindex=1
spentindex=1

# RPC settings
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcallowip=${RPC_ALLOW_IP}
rpcbind=0.0.0.0
rpcport=8332

# Network connectivity
listen=1
port=8333
maxconnections=125

# Logging
debug=0
printtoconsole=1

# Performance
dbcache=256
maxmempool=300

# Network mode
EOF
    
    if [ "$NETWORK" = "testnet" ]; then
      echo "testnet=1" >> "$CONF_FILE"
    elif [ "$NETWORK" = "regtest" ]; then
      echo "regtest=1" >> "$CONF_FILE"
    fi
    
    echo "Konfiguration erstellt: RPC_USER=${RPC_USER}, NETWORK=${NETWORK}"
  else
    echo "Warnung: Keine Konfigurationsvorlage gefunden unter $CONFIG_TEMPLATE"
    echo "Erstelle minimale Standardkonfiguration..."
    RPC_USER=${RPC_USER:-user}
    RPC_PASSWORD=${RPC_PASSWORD:-$(openssl rand -hex 16)}
    RPC_ALLOW_IP=${RPC_ALLOW_IP:-0.0.0.0/0}
    NETWORK=${NETWORK:-mainnet}
    cat > "$CONF_FILE" <<EOF
server=1
daemon=0
txindex=1
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcallowip=${RPC_ALLOW_IP}
rpcbind=0.0.0.0
listen=1
EOF
  fi
  echo "Erstellte Konfiguration unter $CONF_FILE"
fi

# Prüfen, ob Binärdateien vorhanden sind
if ! command -v bitd >/dev/null 2>&1; then
  echo "Fehler: 'bitd' wurde nicht gefunden. Stelle sicher, dass die Dockerfile-Installation erfolgreich war." >&2
  exit 1
fi

# Argumente zusammenbauen
EXTRA_ARGS=()
if [ "${NETWORK:-mainnet}" = "testnet" ]; then
  EXTRA_ARGS+=("-testnet")
fi
if [ "${NETWORK:-mainnet}" = "regtest" ]; then
  EXTRA_ARGS+=("-regtest")
fi

EXTRA_ARGS+=("-conf=${CONF_FILE}")
EXTRA_ARGS+=("-datadir=${DATADIR}")

# Optional: weitergereichte Argumente an bitd anhängen
if [ $# -gt 0 ]; then
  EXTRA_ARGS+=("$@")
fi

echo "Starte bitd mit Datenverzeichnis ${DATADIR}"
exec gosu "$USER_ID":"$GROUP_ID" bitd "${EXTRA_ARGS[@]}"


