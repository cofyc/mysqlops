#!/bin/bash
#
# This script is used to generate MySQL configuration file.
#
# References:
#
# - https://tools.percona.com/wizard
#

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source "${ROOT}/cluster/lib/init.sh"

function usage() {
    cat <<EOF 1>&2
Usage: $(basename $0) -d <data_dir> -p <password> -e <production|development> -b <bind_address> -n <cluste_name> -c <cluster_address> -s <sst_password> -v [5.6|5.7]

Examples:

    $(basename $0) -d /disk1/mysql -p password -e production -b 192.168.160.1 -n pxc_cluster -c 192.168.160.1,192.168.160.2,192.168.160.3 -s <sst_password>

EOF
}

ENVIRONMENT=production
DATA_DIR=/var/lib/mysql
PASSWORD=root
BIND_ADDRESS="0.0.0.0"
CLUSTER_ADDRESS=""
CLUSRER_NAME="pxc_cluster"
SST_PASSWORD="s3cret"
MYSQL_VERSION="5.7"
SERVER_ID=""

while getopts "h?p:e:d:b:c:n:s:v:i:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
        ;;
    p)
        PASSWORD="$OPTARG"
        ;;
    e)
        ENVIRONMENT="$OPTARG"
        ;;
    d)
        DATA_DIR="${OPTARG%/}"
        ;;
    b)
        BIND_ADDRESS="${OPTARG}"
        ;;
    c)
        CLUSTER_ADDRESS="${OPTARG}"
        ;;
    n)
        CLUSTER_NAME="${OPTARG}"
        ;;
    s)
        SST_PASSWORD="${OPTARG}"
        ;;
    v)
        MYSQL_VERSION="${OPTARG}"
        ;;
    i)
        SERVER_ID="${OPTARG}"
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

if [ "$MYSQL_VERSION" != "5.6" -a "$MYSQL_VERSION" != "5.7" ]; then
    echo "error: only 5.6/5.7 versions are supported" 1>&2
    usage
    exit 1
fi

if [ "$MYSQL_VERSION" == "5.7" ]; then
    if [ -z "$SERVER_ID" ]; then
        echo "error: in 5.7, server_id should be specified, please specify by '-i <server_id>'" 1>&2
        usage
        exit 2
    fi
fi

function find_libgalera_ssm_path() {
    for f in /usr/lib/libgalera_smm.so /usr/lib64/libgalera_smm.so; do
        if test -e "$f"; then
        echo "$f"
        return
        fi
    done
}

function calc_innodb_buffer_pool_size() {
    local m=$(($GRAIN_MEM_TOTAL / 2 / 1024 / 1024))
    if [[ $m -ge 1024 ]]; then
        # >= 1G
        m=$(($m / 1024))
        echo "${m}G"
    elif [[ $m -ge 5 ]]; then
        # >= 5M and < 1024M
        echo "${m}M"
    else
        # otherwise, use minimal value
        echo "5M"
    fi
}

echo "ENVIRONMENT: $ENVIRONMENT" 1>&2
echo "DATA_DIR: $DATA_DIR" 1>&2
echo "PASSWORD: $PASSWORD" 1>&2
echo "BIND_ADDRESS: $BIND_ADDRESS" 1>&2
echo "CLUSTER_NAME: $CLUSTER_NAME" 1>&2
echo "CLUSTER_ADDRESS: $CLUSTER_ADDRESS" 1>&2
echo "SST_PASSWORD: $SST_PASSWORD" 1>&2
echo "MYSQL_VERSION: $MYSQL_VERSION" 1>&2

INNODB_BUFFER_SIZE="32M"
INNODB_LOGFILE_SIZE="32M"
MAX_CONNECTIONS="128"
TABLE_DEFINITION_CACHE="128"
TABLE_OPEN_CACHE="128"
if [[ "$ENVIRONMENT" == "development" ]]; then
    :
elif [[ "$ENVIRONMENT" == "production" ]]; then
    INNODB_BUFFER_SIZE="$(calc_innodb_buffer_pool_size)"
    INNODB_LOGFILE_SIZE="512M"
    MAX_CONNECTIONS="4096"
    TABLE_DEFINITION_CACHE="1024"
    TABLE_OPEN_CACHE="2048"
else
    usage
    exit 0
fi

RUN_DIR="/var/run/mysqld"

cat <<EOF
[client]

# CLIENT #
user                           = root
password                       = ${PASSWORD}
port                           = 3306
socket                         = ${RUN_DIR}/mysql.sock

[mysqld]

# GENERAL #
user                           = mysql
default-storage-engine         = InnoDB
socket                         = ${RUN_DIR}/mysql.sock
pid-file                       = ${RUN_DIR}/mysql.pid
bind-address                   = ${BIND_ADDRESS}

EOF

if [ "$CLUSTER_ADDRESS" != "" ]; then
#
# Configure PXC Gelera Options.
#

LIBGALERA_SSM_PATH=$(find_libgalera_ssm_path)
echo "LIBGALERA_SSM_PATH: $LIBGALERA_SSM_PATH" 1>&2
if [ -z "$LIBGALERA_SSM_PATH" ]; then
    echo "libgalera_smm.so not found"
    exit 1
fi

    cat <<EOF
# WSREP #

# Path to Galera library
wsrep_provider                 = ${LIBGALERA_SSM_PATH}
wsrep_provider_options         = "gcache.size=512M"

# Cluster connection URL contains the IPs of all possible nodes
wsrep_cluster_address          = gcomm://${CLUSTER_ADDRESS}

# See https://www.percona.com/doc/percona-xtradb-cluster/5.6/wsrep-system-index.html#wsrep_sync_wait.
wsrep_sync_wait                = 0

# Node address
wsrep_node_address             = ${BIND_ADDRESS}

# SST method
wsrep_sst_method               = xtrabackup-v2

# Cluster name
wsrep_cluster_name             = ${CLUSTER_NAME}

# Authentication for SST method
wsrep_sst_auth                 = "sstuser:${SST_PASSWORD}"
EOF
fi

cat <<EOF

# MyISAM #
key-buffer-size                = 32M

# SAFETY #
max-allowed-packet             = 16M
max-connect-errors             = 1000000
skip-name-resolve
sql-mode                       = NO_ENGINE_SUBSTITUTION
sysdate-is-now                 = 1

# DATA STORAGE #
datadir                        = ${DATA_DIR}

# BINARY LOGGING #
log-bin                        = ${DATA_DIR}/mysql-bin
expire-logs-days               = 14
sync-binlog                    = 1
# In order for Galera to work correctly binlog format should be ROW
binlog_format                  = ROW
# Uncomment following lines if you want to replicate asynchronously from a
# non-member of the cluster.
# Note: servier_id should be unique.
# In 5.7, server_id should be specifed if you enabled binary logging.
server_id                      = ${SERVER_ID}
#log_slave_updates
#relay-log                      = mysql-relay-bin

# CACHES AND LIMITS #
tmp-table-size                 = 32M
max-heap-table-size            = 32M
query-cache-type               = 0
query-cache-size               = 0
max-connections                = ${MAX_CONNECTIONS}
thread-cache-size              = 100
open-files-limit               = 65535
table-definition-cache         = ${TABLE_DEFINITION_CACHE}
table-open-cache               = ${TABLE_OPEN_CACHE}

# INNODB #
innodb                         = FORCE
innodb-strict-mode             = 1
innodb-flush-method            = O_DIRECT
innodb-log-files-in-group      = 2
innodb-log-file-size           = ${INNODB_LOGFILE_SIZE}
innodb-flush-log-at-trx-commit = 1
innodb-file-per-table          = 1
innodb-buffer-pool-size        = ${INNODB_BUFFER_SIZE}
EOF

if [ "$CLUSTER_ADDRESS" != "" ]; then

    cat <<EOF

# This changes how InnoDB autoincrement locks are managed and is a requirement
# for Galera.
innodb_autoinc_lock_mode       = 2
EOF

fi

    cat <<EOF

# LOGGING #
log-error                      = ${DATA_DIR}/mysql-error.log
slow-query-log                 = 1
slow-query-log-file            = ${DATA_DIR}/mysql-slow.log

# CHARSET #
character-set-server          = utf8
collation-server              = utf8_general_ci

# MISC #
explicit_defaults_for_timestamp

EOF
