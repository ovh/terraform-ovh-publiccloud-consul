#!/bin/bash
# shellcheck source=/dev/null
source "$(dirname "$0")/functions.sh"

watch(){
    exec "${CONSUL_BIN}" watch -type=keyprefix -prefix="${KV_CACERTS_PREFIX}" "${SCRIPT_DIR}/watch-cacerts.sh"
}

handler(){
    for i in $(jq -r '.[]|[.Key,.Value]|join(",")'); do
        echo "$i" | cut -d, -f2 | base64 -d | tee "$CACERTS_INSTALL_DIR/$(echo "$i" | cut -d, -f1 | sed 's/\//_/g' ).pem"
    done
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
