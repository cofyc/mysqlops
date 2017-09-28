#!/bin/bash
#
# This script is used to install Percona Server.
#
# References:
#
# - https://www.percona.com/doc/percona-server/LATEST/index.html
#

ROOT=$(unset CDPATH && cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd)
cd $ROOT

source "${ROOT}/cluster/lib/init.sh"

function usage() {
    local rootpass=$(uuidgen)
    cat <<EOF
Usage: $(basename $0) [-h] -d <data_dir> -b <bind_address> -p <password> -e [development|production] -v [5.6|5.7] -i <server_id>

Examples:

    $(basename $0) -d /disk1/mysql -b 192.168.224.7 -p $rootpass -e production -i 1

EOF
}

ENVIRONMENT=production
DATA_DIR=/var/lib/mysql
BIND_ADDRESS="0.0.0.0"
PASSWORD="root"
MYSQL_VERSION="5.7"
SERVER_ID=""
SKIP_UPDATE_REPO=""

while getopts "h?d:b:c:e:p:s:v:i:n" opt; do
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
    e)
        ENVIRONMENT="${OPTARG}"
        ;;
    p)
        PASSWORD="${OPTARG}"
        ;;
    v)
        MYSQL_VERSION="${OPTARG}"
        ;;
    i)
        SERVER_ID="${OPTARG}"
        ;;
    n)
        SKIP_UPDATE_REPO="true"
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

echo "GRAIN_OS: $GRAIN_OS"
echo "MYSQL_VERSION: $MYSQL_VERSION"
echo "ENVIRONMENT: $ENVIRONMENT"
echo "DATA_DIR: $DATA_DIR"
echo "BIND_ADDRESS: $BIND_ADDRESS"
echo "PASSWORD: $PASSWORD"
echo "ARGS: $@"

if [ "$MYSQL_VERSION" == "5.6" ]; then
    APT_PKG="percona-server-server-5.6"
    YUM_PKG="Percona-Server-server-56"
elif [ "$MYSQL_VERSION" == "5.7" ]; then
    APT_PKG="percona-server-server-5.7"
    YUM_PKG="Percona-Server-server-57"
fi

# setup percona repo
if [ "$SKIP_UPDATE_REPO" == "" ]; then
    $ROOT/cluster/setup.sh
fi

# install mysql
if ps -Cmysqld &>/dev/null; then
    echo "MySQL is running, exit."
    exit 1
elif ! which mysqld &>/dev/null; then
    echo "Installing MySQL..."
    if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
        debconf-set-selections <<< "percona-server-server-${MYSQL_VERSION} percona-server-server-${MYSQL_VERSION}/root-pass password ${PASSWORD}"
        debconf-set-selections <<< "percona-server-server-${MYSQL_VERSION} percona-server-server-${MYSQL_VERSION}/re-root-pass password ${PASSWORD}"
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
        if which systemctl &>/dev/null; then
            systemctl stop mysql
        else
            /etc/init.d/mysql stop
        fi
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

# install percona-toolkit
if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
    apt-get install -y percona-toolkit
elif [[ "$GRAIN_OS" == "CentOS" ]]; then
    yum install -y percona-toolkit
fi

# Configure my.cnf.

## Save old MySQL configuration files first.
for f in /etc/my.cnf /etc/mysql/my.cnf; do
    test -f $f && mv $f ${f}.save
done
if [ "$GRAIN_OS" == "Ubuntu" ]; then
    # Hack to make /usr/share/mysql/mysql-systemd-start happy.
    touch /etc/mysql/my.cnf
fi

## We only writes /etc/my.cnf because it has highest precedence.
MYSQL_CNF_FILE=/etc/my.cnf
kube::log::status "Configuring $MYSQL_CNF_FILE."
$ROOT/cluster/gen-my-conf.sh -d $DATA_DIR -p "$PASSWORD" -e $ENVIRONMENT \
  -b "$BIND_ADDRESS" \
  -v "$MYSQL_VERSION" \
  -i "$SERVER_ID" \
  > $MYSQL_CNF_FILE
if [ $? -ne 0 ]; then
    kube::log::status "Configuring $MYSQL_CNF_FILE failed."
    exit 1
fi
kube::log::status "Configuring $MYSQL_CNF_FILE done."

# Configure logrotate.
#
# We use logrotate to rotate mysql slow logs.
#
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
kube::log::status "Checking SELinux."
if which selinuxenabled &>/dev/null; then
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
        kube::log::status "SELinux is disabled, skipped."
    fi
else
    kube::log::status "SELinux not found, skipped."
fi

# AppArmor (TODO)

# init database
if [ "$MYSQL_VERSION" == "5.7" ]; then
    # Since 5.7, mysql_install_db is deprecated.
    mysqld --initialize-insecure --user=mysql --basedir=/usr
else
    mysql_install_db --user=mysql --basedir=/usr
fi

# start
if which systemctl &>/dev/null; then
    if [[ "$GRAIN_OS" == "Ubuntu" ]]; then
        SERVER_NAME=mysql
    else
        SERVER_NAME=mysqld
    fi
    systemctl start $SERVER_NAME
    systemctl_status=$(systemctl is-enabled $SERVER_NAME)
    if [ "$systemctl_status" != "enabled" ]; then
        kube::log::status "`$SERVER_NAME` is not enabled, enabling it..."
        systemctl enable $SERVER_NAME
    fi
else
    /etc/init.d/mysql start
fi

# Change root password (default password is empty) and make sure root user can
# access from 'localhost', '127.0.0.1' and '::1'.
kube::log::status "Configuring root user."
mysql --host localhost --user=root --password='' -e "GRANT ALL PRIVILEGES ON *.* TO root@'127.0.0.1' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION;"
mysql --host localhost --user=root --password='' -e "GRANT ALL PRIVILEGES ON *.* TO root@'::1' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION;"
mysql --host localhost --user=root --password='' -e "GRANT ALL PRIVILEGES ON *.* TO root@'localhost' IDENTIFIED BY '$PASSWORD' WITH GRANT OPTION;"
if [ $? -eq 0 ]; then
    kube::log::status "Configuring root user done."
else
    kube::log::status "Failed to configure root user."
fi

## Secure Your MySQL Installation.
# This simplies do what `mysql_secure_installation` do.

kube::log::status "Securing your MySQL installation."
# secure/remove_anonymous_users
mysql -e "DELETE FROM mysql.user WHERE User = '';"
# secure/remove_remote_root
mysql -e "DELETE FROM mysql.user WHERE User = 'root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
# secure/remove_test_database
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
# flush privileges
mysql -e "FLUSH PRIVILEGES;"
kube::log::status "Done."
