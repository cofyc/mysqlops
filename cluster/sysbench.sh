#!/bin/bash
#
# See https://www.percona.com/docs/wiki/benchmark:sysbench:olpt.lua.
# See https://github.com/akopytov/sysbench.
#

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source "${ROOT}/cluster/lib/init.sh"

TESTS=$(cd sysbench/tests && ls oltp_*.lua | sed -r 's/oltp_([a-z_]+)\.lua/\1/g' | grep -v common)

function usage() {
    echo "Usage: $0 [test] [prepare|run|cleanup]"
    echo ""
    echo "Available tests:"
    for t in $TESTS; do
        echo "    $t"
    done
}

if [ $# -lt 2 ]; then
    usage
    exit
fi

function in_list() {
    local e
    for e in "${@:2}"; do
        [[ "$e" == "$1" ]] && return 0;
    done
    return 1
}

t=$1
action=$2

if ! in_list "$t" $TESTS; then
    echo "error: invalid test"
    usage
    exit
fi

if ! which sysbench &>/dev/null; then
    if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
        if ! apt::is_pkg_installed sysbench; then
            apt-get install -y sysbench
        fi
    elif [[ "$GRAIN_OS" == "CentOS" ]]; then
        :
    fi
fi

sysbench \
    --mysql-host=127.0.0.1 \
    --mysql-port=3306 \
    --mysql-user=cu \
    --mysql-password=cu \
    --mysql-db=clusterup \
    --mysql-ignore-errors=all \
    --report-interval=1 \
    --max-requests=0 \
    --rate=10 \
    --threads=10 \
    sysbench/tests/oltp_$t.lua \
    $action
