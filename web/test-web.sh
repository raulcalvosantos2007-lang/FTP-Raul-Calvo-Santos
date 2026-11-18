#!/usr/bin/env bash
#
# Comprueba que Apache sirve la página publicada por Ansible.
#
# Uso:
#   ./web/test-web.sh
#   WEB_IP=192.168.57.7 DOMAIN=raul.test ./web/test-web.sh
#
set -euo pipefail

WEB_IP="${WEB_IP:-192.168.57.7}"
DOMAIN="${DOMAIN:-raul.test}"
URL="${URL:-http://www.${DOMAIN}/}"
EXPECTED="${EXPECTED:-Servidor web de ${DOMAIN}}"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: se necesita el comando 'curl'." >&2
    exit 2
fi

# --resolve evita depender de que el DNS del anfitrión ya apunte al servidor.
body="$(curl -fsS --resolve "www.${DOMAIN}:80:${WEB_IP}" "${URL}")"

if grep -q "${EXPECTED}" <<<"${body}"; then
    echo "OK: ${URL} responde y contiene '${EXPECTED}'."
else
    echo "FAIL: ${URL} no contiene '${EXPECTED}'." >&2
    exit 1
fi
