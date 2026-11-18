#!/usr/bin/env bash
#
# Comprueba los registros directos e inversos del servidor DNS de la práctica.
#
# Uso:
#   ./dns/test-dns.sh
#   DNS_SERVER=192.168.57.5 DOMAIN=raul.test ./dns/test-dns.sh
#
set -uo pipefail

DNS_SERVER="${DNS_SERVER:-192.168.57.5}"
DOMAIN="${DOMAIN:-raul.test}"

if ! command -v dig >/dev/null 2>&1; then
    echo "ERROR: se necesita el comando 'dig' (paquete dnsutils/bind9-dnsutils)." >&2
    exit 2
fi

fail=0

check_a() {
    local name="$1"
    local expected="$2"
    local got

    # Se usa el último valor para quedarnos con la IP cuando la respuesta
    # incluye también el CNAME.
    got="$(dig +short "@${DNS_SERVER}" A "${name}" | tail -n 1)"

    if [[ "${got}" == "${expected}" ]]; then
        printf 'OK   %-28s -> %s\n' "${name}" "${got}"
    else
        printf 'FAIL %-28s -> %s (esperado %s)\n' "${name}" "${got:-<vacío>}" "${expected}"
        fail=1
    fi
}

check_ptr() {
    local ip="$1"
    local expected="$2"
    local got

    got="$(dig +short "@${DNS_SERVER}" -x "${ip}" | head -n 1)"

    if [[ "${got}" == "${expected}" ]]; then
        printf 'OK   %-28s -> %s\n' "${ip} (PTR)" "${got}"
    else
        printf 'FAIL %-28s -> %s (esperado %s)\n' "${ip} (PTR)" "${got:-<vacío>}" "${expected}"
        fail=1
    fi
}

echo "Servidor DNS: ${DNS_SERVER}"
echo "Dominio:      ${DOMAIN}"
echo

check_a "dns.${DOMAIN}"     "192.168.57.5"
check_a "negocio.${DOMAIN}" "192.168.57.7"
check_a "www.${DOMAIN}"     "192.168.57.7"
check_a "ftp.${DOMAIN}"     "192.168.57.7"

echo

check_ptr "192.168.57.5" "dns.${DOMAIN}."
check_ptr "192.168.57.7" "negocio.${DOMAIN}."

echo

if [[ "${fail}" -ne 0 ]]; then
    echo "Hay comprobaciones DNS fallidas." >&2
    exit 1
fi

echo "Todas las comprobaciones DNS han pasado."
