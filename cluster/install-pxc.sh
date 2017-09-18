#!/bin/bash
#
# This script is used to install PXC cluster.
#

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source "${ROOT}/cluster/lib/init.sh"

function usage() {
    local rootpass=$(uuidgen)
    local sstpass=$(uuidgen)
    cat <<EOF
Usage: $(basename $0) [-h] -d <data_dir> -b <bind_address> -c <cluster_address> -p <password> -s <root_password> -e [development|production] -v [5.6|5.7] [bootstrap] 

Examples:

    # bootstrap PXC cluster 
    $(basename $0) -d /disk1/mysql -b 192.168.224.7 -c 192.168.224.7,192.168.224.17,192.168.224.27 -p $rootpass -s $sstpass -e production bootstrap

    # add node into PXC cluster
    $(basename $0) -d /disk1/mysql -b 192.168.224.17 -c 192.168.224.7,192.168.224.17,192.168.224.27 -p $rootpass -s $sstpass -e production
    $(basename $0) -d /disk1/mysql -b 192.168.224.27 -c 192.168.224.7,192.168.224.17,192.168.224.27 -p $rootpass -s $sstpass -e production

EOF
}

ENVIRONMENT=production
DATA_DIR=/var/lib/mysql
BIND_ADDRESS="0.0.0.0"
CLUSTER_ADDRESS=""
CLUSTER_NAME="pxc_cluster"
PASSWORD="root"
SST_PASSWORD="sstpass"
MYSQL_VERSION="5.7"
SERVER_ID=""

while getopts "h?d:b:c:e:p:s:v:i:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
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
    e)
        ENVIRONMENT="${OPTARG}"
        ;;
    p)
        PASSWORD="${OPTARG}"
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
    echo "error: only 5.6/5.7 versions are supported"
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

echo "ENVIRONMENT: $ENVIRONMENT"
echo "DATA_DIR: $DATA_DIR"
echo "BIND_ADDRESS: $BIND_ADDRESS"
echo "CLUSTER_ADDRESS: $CLUSTER_ADDRESS"
echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "PASSWORD: $PASSWORD"
echo "SST_PASSWORD: $SST_PASSWORD"
echo "ARGS: $@"

if [ "$MYSQL_VERSION" == "5.6" ]; then
    APT_PKG="percona-xtradb-cluster-56"
    YUM_PKG="Percona-XtraDB-Cluster-56"
elif [ "$MYSQL_VERSION" == "5.7" ]; then
    APT_PKG="percona-xtradb-cluster-57"
    YUM_PKG="Percona-XtraDB-Cluster-57"
fi

# setup percona repo
$ROOT/cluster/setup.sh

# install mysql
if ps -Cmysqld &>/dev/null; then
    echo "MySQL is running, exit."
    exit 1
elif ! which mysqld &>/dev/null; then
    echo "Installing MySQL..."
    if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
        debconf-set-selections <<< "mysql-server percona-xtradb-cluster-server/root_password password ${PASSWORD}"
        debconf-set-selections <<< "mysql-server percona-xtradb-cluster-server/root_password_again password ${PASSWORD}"
        # Clear old my.cnf.
        test -f /etc/my.cnf && rm /etc/my.cnf
        # Use low memory configurations to make sure it's able to start MySQL
        # on low memory machine to configure MySQL package (for dpkg --configure).
        mkdir -p /etc/mysql/conf.d
        cat <<EOF > /etc/mysql/conf.d/hack.cnf
[mysqld]
performance_schema=0
innodb_buffer_pool_size=5M
innodb_log_buffer_size=256K
query_cache_size=0
EOF
        apt-get install -y $APT_PKG
        /etc/init.d/mysql stop
    elif [[ "$GRAIN_OS" == "CentOS" ]]; then
        yum install -y $YUM_PKG
    fi
else
    read -r -p "MySQL is installed, are you sure installed MySQL is what you want? [y/N] " response
    if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Exit."
        exit 1
    fi
fi

# install percona-toolkit & xinetd
if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
    apt-get install -y percona-toolkit
    apt-get install -y xinetd
elif [[ "$GRAIN_OS" == "CentOS" ]]; then
    yum install -y percona-toolkit
    yum install -y xinetd
fi

# my.cnf

## clear default configuration files
test -f /etc/mysql/my.cnf && mv /etc/mysql/my.cnf /etc/mysql/my.cnf.defaults
kube::log::status "Configuring /etc/my.conf."
$ROOT/cluster/gen-my-conf.sh -d $DATA_DIR -p "$PASSWORD" -e $ENVIRONMENT \
  -b "$BIND_ADDRESS" \
  -n "$CLUSTER_NAME" \
  -c "$CLUSTER_ADDRESS" \
  -s "$SST_PASSWORD" \
  -v "$MYSQL_VERSION" \
  -i "$SERVER_ID" \
  > /etc/my.cnf
if [ $? -ne 0 ]; then
    kube::log::status "Configuring /etc/my.conf failed."
    exit 1
fi
kube::log::status "Configuring /etc/my.conf done."

## install logrotate file
cat <<EOF > /etc/logrotate.d/mysql
${DATA_DIR}/mysql-slow.log {
    nocompress
    create 660 mysql mysql
    size 1G
    dateext
    missingok
    notifempty
    sharedscripts
    postrotate
       /usr/bin/mysql -e 'select @@global.long_query_time into @lqt_save; set global long_query_time=2000; select sleep(2); FLUSH LOGS; select sleep(2); set global long_query_time=@lqt_save;'
    endscript
    rotate 15
}
EOF

# check data dir
if test -d "$DATA_DIR" -a $(ls $DATA_DIR/* 2>/dev/null | wc -l) -gt 2; then
    echo "$DATA_DIR exists and not empty, please clean before install MySQL database here."
    exit 1
fi
test -d "$DATA_DIR" || mkdir -p "$DATA_DIR"
chown mysql:mysql $DATA_DIR

# SELinux
kube::log::status "Configuring SELinux."
if selinuxenabled; then
    if semodule -lstandard | grep mysql &>/dev/null; then
        kube::log::status "Disabling SELinux mysql module."
        semodule -d mysql
        kube::log::status "Disabling SELinux mysql module done."
    else
        kube::log::status "SELinux mysql module is not enabled, skip."
    fi
else
    kube::log::status "SELinux is disabled, skip."
fi

# AppArmor (TODO)

# start
if [ "$1" == 'bootstrap' ]; then
    # init database
    if [ "$MYSQL_VERSION" == "5.7" ]; then
        # Since 5.7, mysql_install_db is deprecated.
        mysqld --initialize-insecure --user=mysql --basedir=/usr
    else
        mysql_install_db --user=mysql --basedir=/usr
    fi
    # start
    if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
        /etc/init.d/mysql bootstrap-pxc
    elif [[ "$GRAIN_OS" == "CentOS" ]]; then
        systemctl start mysql@bootstrap
    fi
    # change root password (default password is empty)
    mysqladmin --user=root --password='' password "$PASSWORD" # from localhost
    mysqladmin --host 127.0.0.1 --user=root --password='' password "$PASSWORD" # from 127.0.0.1
    # setup sst user
    mysql -e "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sstuser'@'localhost' IDENTIFIED BY '${SST_PASSWORD}';"
    # setup cluster check user
    mysql -e 'GRANT PROCESS ON *.* TO "clustercheckuser"@"localhost" IDENTIFIED BY "clustercheckpassword!";'
    # do what mysql_secure_installation do
    # secure/remove_anonymous_users
    mysql -e "DELETE FROM mysql.user WHERE User='';"
    # secure/remove_remote_root
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    # secure/remove_test_database
    mysql -e "DROP DATABASE IF EXISTS test;"
    mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
    # flush privileges
    mysql -e "FLUSH PRIVILEGES;"
else
    if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
        /etc/init.d/mysql start
    elif [[ "$GRAIN_OS" == "CentOS" ]]; then
        systemctl start mysql
    fi
fi

grep -q -F 'mysqlchk 9200/tcp' /etc/services || echo 'mysqlchk 9200/tcp # mysqlchk' >> /etc/services 
if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
    /etc/init.d/xinetd restart
elif [[ "$GRAIN_OS" == "CentOS" ]]; then
    # Remove only_from value, old value "0.0.0.0/0" is only for IPv4, may deny "::1".
    sed -i -r "/(only_from *= *).*/d" /etc/xinetd.d/mysqlchk
    systemctl restart xinetd
fi

if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
    update-rc.d xinetd enable
    update-rc.d mysql enable
elif [[ "$GRAIN_OS" == "CentOS" ]]; then
    chkconfig xinetd on
    chkconfig mysql on
fi

$ROOT/cluster/check-pxc-status.sh 

#
# vim: ft=sh tw=0
#
