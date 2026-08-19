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
# Wichtig: Bestehende bit.conf wird NIE überschrieben (RPC-Credentials o.ä. bleiben erhalten).
# Falls bereits addnode-Bootstrap-Einträge fehlen, werden sie nur angehängt (Merge).
APPEND_ADDNODE_BLOCK() {
  if ! grep -qE '^[[:space:]]*addnode=' "$CONF_FILE"; then
    echo "Ergänze addnode-Bootstrap-Peers in $CONF_FILE"
    cat >> "$CONF_FILE" <<'EOF'

# Bootstrap peers (fallback until DNS seeds are compiled into releases)
addnode=167.86.89.107:33317
addnode=45.146.252.138:33317
addnode=92.42.45.220:33317
EOF
  fi
}

if [ ! -f "$CONF_FILE" ]; then
  if [ -f "$CONFIG_TEMPLATE" ]; then
    echo "Keine Konfiguration gefunden, erzeuge neue aus Umgebung (Ports gemäß Chain-Defaults: P2P 33317, RPC 45873)"
  else
    echo "Warnung: Keine Konfigurationsvorlage gefunden unter $CONFIG_TEMPLATE"
    echo "Erstelle minimale Standardkonfiguration..."
  fi

  # Ersetze Platzhalter mit Umgebungsvariablen
  RPC_USER=${RPC_USER:-user}
  RPC_PASSWORD=${RPC_PASSWORD:-$(openssl rand -hex 16)}
  RPC_ALLOW_IP=${RPC_ALLOW_IP:-0.0.0.0/0}
  NETWORK=${NETWORK:-mainnet}

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

# RPC settings (chain default rpcport: 45873)
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcallowip=${RPC_ALLOW_IP}
rpcbind=0.0.0.0
rpcport=45873

# Network connectivity (chain default port: 33317)
listen=1
port=33317
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

  # Bootstrap peers (fallback until DNS seeds are compiled into releases)
  cat >> "$CONF_FILE" <<'EOF'

# Bootstrap peers (fallback until DNS seeds are compiled into releases)
addnode=167.86.89.107:33317
addnode=45.146.252.138:33317
addnode=92.42.45.220:33317
EOF

  echo "Konfiguration erstellt: RPC_USER=${RPC_USER}, NETWORK=${NETWORK}"
  echo "Erstellte Konfiguration unter $CONF_FILE"
else
  # Bestehende Konfiguration: nur Merge, niemals überschreiben
  APPEND_ADDNODE_BLOCK
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


