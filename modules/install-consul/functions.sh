#!/bin/bash
# shellcheck source=/dev/null
readonly SCRIPT_FILE="$0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"

function log(){
    if ! tty -s; then logger -s -t "$CONSUL_SERVICE_NAME" -p "$@"; else echo "$@" >&2; fi;
}

if [ -f "${SCRIPT_DIR}/defaults.conf" ]; then
    log user.info "loading defaults"
    source "${SCRIPT_DIR}/defaults.conf"
fi

if [ -f "/etc/sysconfig/consul.conf" ]; then
    log user.info "loading /etc/sysconfig/consul.conf"
    source "/etc/sysconfig/consul.conf"
fi

# support for fedora family
CACERTS_INSTALL_DIR=$(if which yum > /dev/null; then echo "/etc/pki/ca-trust/source/anchors"; else echo "${CACERTS_INSTALL_DIR}"; fi)

function lookup_path_in_instance_metadata {
    local readonly path="$1"
    curl --fail --silent --show-error --location "$INSTANCE_METADATA_URL/$path/"
}

function metadata_priv_ipv4 {
    lookup_path_in_instance_metadata "local-ipv4"
}
function metadata_pub_ipv4 {
    lookup_path_in_instance_metadata "public-ipv4"
}
function metadata_instance_id {
    lookup_path_in_instance_metadata "instance-id"
}

function getipaddrfornetwork(){
    NETWORK="$1"
    # Keep trying to retrieve IP addr until it succeeds. Timeouts after 1m
    now=$(date +%s)
    timeout=$(( now + 60 ))
    set +e
    while :; do
        if [[ $timeout -lt $(date +%s) ]]; then
            log user.error "Could not retrieve IP Address. Exiting"
            exit 5
        fi
        if ip route get "$NETWORK" > /dev/null 2>&1; then
          break
        fi
        sleep 1
    done
    ip -o route get "$NETWORK" | sed 's/.*src \([0-9\.]*\) .*/\1/g'
}

function althostname(){
    metadata_instance_id || (getprivipaddr | sed "s/\./-/g")
}

function getpubipaddr(){
    if [ ! -z "$(metadata_pub_ipv4)" ]; then
        echo "$(metadata_pub_ipv4)"
    else
        getipaddrfornetwork "${PUBLIC_NETWORK:-8.8.8.8/32}"
    fi
}

function getprivipaddr(){
    if [ ! -z "$(metadata_priv_ipv4)" ]; then
        echo "$(metadata_priv_ipv4)"
    elif [ ! -z "$PRIVATE_NETWORK" ]; then
        getipaddrfornetwork "$PRIVATE_NETWORK"
    else
        getpubipaddr
    fi
}

function consulbin() {
    "$CONSUL_BIN" "$@"
}

function joinby {
    local IFS="$1";
    shift;
    echo "$*";
}

function fail(){
    set -e
    "$@"
    set +e
}
