#!/bin/bash

if ps -Cmysqld &>/dev/null; then
   echo "MySQL is running, please make sure you DO NOT need it anymore, then manully stop it."
   exit 1
fi

read -r -p "This will remove your MySQL installation, are you sure? [y/N] " response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
   echo "Exit."
   exit 0
fi

# remove and purge percona-xtradb-cluster-56
apt remove --purge percona-xtradb-cluster-56
apt remove --purge percona-xtradb-cluster-server-5.6
apt remove --purge percona-xtradb-cluster-client-5.6
apt remove --purge percona-xtradb-cluster-galera-3
apt remove --purge percona-xtradb-cluster-galera-3.x
apt remove --purge percona-xtradb-cluster-common-5.6
apt remove --purge percona-xtrabackup

# remove and purge percona-toolkit
apt remove --purge percona-toolkit
