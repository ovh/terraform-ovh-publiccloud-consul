#!/bin/bash

DIR=${1:-$(dirname $0)/../examples/consul-cluster}
REGION=${2:-$OS_REGION_NAME}
DESTROY=${3:-1}
CLEAN=${4:-1}
PROJECT=${OS_TENANT_ID}
VRACK=${OVH_VRACK_ID}
test_nb_of_consul_members_eq_4(){
    if echo "$DIR" | grep -q cfssl; then
        consul_host="https://localhost:8503"
    else
        consul_host="http://localhost:8500"
    fi

    # timeout is not 60 seconds but 60 loops, each taking at least 1 sec
    local timeout=60
    local inc=0
    local nb_nodes=0

    local user=$(terraform output | awk '/User/ {print $2}')
    local host=$(terraform output | awk '/Hostname/ {print $2}')
    local proxy=$(terraform output | awk '/ProxyCommand/ {print $3}')

    while [ "${nb_nodes}" != "4" ] && [ "$inc" -lt "$timeout" ]; do
        nb_nodes=$(ssh -o UserKnownHostsFile=/dev/null \
                       -o StrictHostKeyChecking=no  \
                       -o "ProxyCommand=ssh -o StrictHostKeyChecking=no ${proxy} ncat %h %p" \
                       "${user}@${host}" \
                       "curl --silent --fail ${consul_host}/v1/catalog/nodes | jq '.|length'")
        sleep 1
        ((inc++))
    done

    if [ "${nb_nodes}" == "4" ]; then
        return 0
    else
        return 1
    fi
}

# if destroy mode, clean previous terraform setup
if [ "${CLEAN}" == "1" ]; then
    (cd "${DIR}" && rm -Rf .terraform *.tfstate*)
fi

# run the full terraform setup
(cd "${DIR}" && terraform init \
	   && terraform apply -auto-approve -var region="${REGION}" -var project_id="${PROJECT}" -var vrack_id="${VRACK}")
EXIT_APPLY=$?

# if terraform went well run test
if [ "${EXIT_APPLY}" == 0 ]; then
    (cd "${DIR}" && test_nb_of_consul_members_eq_4)
    EXIT_APPLY=$?
fi

# if destroy mode, clean terraform setup
if [ "${DESTROY}" == "1" ]; then
    (cd "${DIR}" && terraform destroy -force -var region="${REGION}" -var project_id="${PROJECT}" -var vrack_id="${VRACK}"\
        && rm -Rf .terraform *.tfstate*)
    EXIT_DESTROY=$?
else
    EXIT_DESTROY=0
fi

exit $((EXIT_APPLY+EXIT_DESTROY))
