#!/bin/bash
# Railway wrapper around the official EspoCRM entrypoint.
# 1. Puts data/, custom/ and client/custom/ on one volume (ESPOCRM_STORAGE_DIR).
# 2. Makes Apache listen on $PORT and turns on WebSockets behind /wss.
# 3. Starts the job daemon and the WebSocket server next to Apache.
# 4. Hands over to the official entrypoint (install on first boot, migrate on updates).
set -euo pipefail

APP=/var/www/html
STORAGE="${ESPOCRM_STORAGE_DIR:-/espocrm-storage}"
PORT="${PORT:-80}"

# --- storage on the volume -------------------------------------------------
mkdir -p "$STORAGE/data" "$STORAGE/custom" "$STORAGE/client-custom"
cp -an /usr/src/espocrm-defaults/data/. "$STORAGE/data/"
cp -an /usr/src/espocrm-defaults/custom/. "$STORAGE/custom/"
cp -an /usr/src/espocrm-defaults/client-custom/. "$STORAGE/client-custom/"
chown -R www-data:www-data "$STORAGE/data" "$STORAGE/custom" "$STORAGE/client-custom"

link_dir() { # link_dir <path in app> <path on volume>
    if [ ! -L "$1" ]; then
        rm -r "$1"
        ln -s "$2" "$1"
    fi
}
link_dir "$APP/data" "$STORAGE/data"
link_dir "$APP/custom" "$STORAGE/custom"
link_dir "$APP/client/custom" "$STORAGE/client-custom"

# --- Apache on $PORT --------------------------------------------------------
sed -ri "s/^Listen [0-9]+$/Listen ${PORT}/" /etc/apache2/ports.conf
sed -ri "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

# --- settings ---------------------------------------------------------------
export ESPOCRM_DATABASE_PLATFORM="${ESPOCRM_DATABASE_PLATFORM:-Mysql}"
export ESPOCRM_ADMIN_USERNAME="${ESPOCRM_ADMIN_USERNAME:-admin}"
if [ -z "${ESPOCRM_ADMIN_PASSWORD:-}" ]; then
    echo >&2 "error: ESPOCRM_ADMIN_PASSWORD is empty. Set it on the EspoCRM service and redeploy."
    exit 1
fi
if [ -n "${ESPOCRM_SITE_URL:-}" ]; then
    # Keep siteUrl in step with the domain on every start, not only at install.
    export ESPOCRM_CONFIG_SITE_URL="${ESPOCRM_CONFIG_SITE_URL:-$ESPOCRM_SITE_URL}"
    case "$ESPOCRM_SITE_URL" in
        https://*) wsUrl="wss://${ESPOCRM_SITE_URL#https://}" ;;
        http://*)  wsUrl="ws://${ESPOCRM_SITE_URL#http://}" ;;
        *)         wsUrl="" ;;
    esac
    if [ -n "$wsUrl" ]; then
        export ESPOCRM_CONFIG_WEB_SOCKET_URL="${ESPOCRM_CONFIG_WEB_SOCKET_URL:-${wsUrl%/}/wss}"
    fi
fi
export ESPOCRM_CONFIG_USE_WEB_SOCKET="${ESPOCRM_CONFIG_USE_WEB_SOCKET:-true}"
export ESPOCRM_CONFIG_WEB_SOCKET_PORT="${ESPOCRM_CONFIG_WEB_SOCKET_PORT:-8081}"
export ESPOCRM_CONFIG_WEB_SOCKET_ZERO_M_Q_SUBSCRIBER_DSN="${ESPOCRM_CONFIG_WEB_SOCKET_ZERO_M_Q_SUBSCRIBER_DSN:-tcp://127.0.0.1:7777}"
export ESPOCRM_CONFIG_WEB_SOCKET_ZERO_M_Q_SUBMISSION_DSN="${ESPOCRM_CONFIG_WEB_SOCKET_ZERO_M_Q_SUBMISSION_DSN:-tcp://127.0.0.1:7777}"

cd "$APP"

# Already installed: keep the database connection in step with the variables
# (for example after the MySQL password or host changes).
if [ "$(bin/command config:get isInstalled 2>/dev/null)" = "true" ]; then
    for pair in "host:ESPOCRM_DATABASE_HOST" "port:ESPOCRM_DATABASE_PORT" "dbname:ESPOCRM_DATABASE_NAME" \
                "user:ESPOCRM_DATABASE_USER" "password:ESPOCRM_DATABASE_PASSWORD"; do
        key="${pair%%:*}"; var="${pair#*:}"
        if [ -n "${!var:-}" ]; then
            bin/command config:set "database.$key" "${!var}" >/dev/null
        fi
    done
fi

# --- job daemon and WebSocket server ----------------------------------------
# Both scripts exit at once until the install is done, so loop with a pause.
supervise() { # supervise <name> <script>
    while true; do
        runuser -u www-data -- env PATH="$PATH" "$2" || echo >&2 "$1 exited with $?"
        sleep 5
    done
}
if [[ "${1-}" == apache2* ]]; then
    supervise "espocrm-daemon" /usr/local/bin/docker-daemon.sh &
    supervise "espocrm-websocket" /usr/local/bin/docker-websocket.sh &
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
