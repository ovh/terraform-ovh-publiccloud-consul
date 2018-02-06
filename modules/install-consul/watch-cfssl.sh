#!/bin/bash
# shellcheck source=/dev/null
source "$(dirname "$0")/functions.sh"

watch(){
    exec "${CONSUL_BIN}" watch -type=service -service="${CFSSL_SERVICE_NAME}" -passingonly=true "${SCRIPT_DIR}/watch-cfssl.sh"
}

handler(){
    if curl --silent --fail -X GET "http://127.0.0.1:8500/v1/health/checks/${CFSSL_SERVICE_NAME}" | jq '.[].Status' | grep -q "passing"; then
        # generating new tls certs if there's no certs or existing certs are	 older than one hour."
        if [ ! -f "${CONSUL_CERTDIR}/cert.pem" ] \
               || find "${CONSUL_CERTDIR}/cert.pem" -mmin "+60" | egrep '*' \
               || ! openssl verify -purpose sslserver -CAfile "${CACERTS_INSTALL_DIR}/cacerts_${DATACENTER}_${DOMAIN}.pem" "${CONSUL_CERTDIR}/cert.pem"; then
            log user.info "generating consul new certs (either too old, no existent or invalid)"
            "${SCRIPT_DIR}/consul-manage" cfssl-cert
        fi
    fi
}

case $1 in
    watch)
        log user.info "watch"
        watch
        ;;
    *)
        handler
        ;;
esac
