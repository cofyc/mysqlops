#!/bin/bash
#
# This script is used to grant a mysql user.
#

MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASS=

function usage() {
    cat <<EOF
Usage: $(basename $0) [options] <mysql-user>[:<mysql-pass>][@<mysql-db>]

    -h|-?               show this help message and exit
    -H <mysql-host>     mysql host to connect
    -u <mysql-user>     mysql user used to connect to mysql
    -p <mysql-pass>     mysql pass used to connect to mysql host

Examples:

    $(basename $0) app:mypassword@appdb

EOF
}

while getopts "h?H:b:c:e:p:s:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit 0
    ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

for userspec in $@; do
    user=$(perl -lne 'print "$1" if /^(\w+)(?::(\w+))?(?:@(\w+))?$/' <<<"$userspec")
    pass=$(perl -lne 'print "$2" if /^(\w+)(?::(\w+))?(?:@(\w+))?$/' <<<"$userspec")
    db=$(perl -lne 'print "$3" if /^(\w+)(?::(\w+))?(?:@(\w+))?$/' <<<"$userspec")
    if [ -z "$user" ]; then
        printf "invalid userspec: %s\n" "$userspec"
        exit -1
    fi
    if [ -z "$pass" ]; then
        pass=$(uuidgen)
    fi
    if [ -z "$db" ]; then
        db="*"
    fi
    read -r -p "Grant all privileges on ${db}.* to ${user}@'%' with password: ${pass}? [y/N] " response
    if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Exit."
        exit 0
    fi
    mysql -e "GRANT ALL PRIVILEGES ON ${db}.* TO ${user}@'%' IDENTIFIED BY '${pass}';"
done
