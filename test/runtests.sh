#!/bin/bash

REGIONS=${1:-$OS_REGION_NAME}
DIRS=(consul-cluster consul-cluster-cl consul-cluster-cfssl)

EXIT=0
for d in ${DIRS[@]}; do
    for r in $REGIONS; do
        $(dirname $0)/runtest.sh "$(dirname $0)/../examples/$d" "$r"
        EXIT=$((EXIT+$?))
    done
done

exit $EXIT
