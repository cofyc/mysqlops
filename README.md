# MySQL Operations

## Table of Contents

* [Supported Platforms](#supported-platforms)
* [Supported MySQL Distributions](#supported-mysql-distributions)
* [Development](#development)
* [Operations](#operation)
  * [Install PXC on bare metal machines](#install-pxc-on-bare-metal-machines)
    * [PXC single-node cluster](#pxc-single-node-cluster)
    * [PXC multi-node cluster](#pxc-multi-node-cluster)
    * [Install HAProxy on client](#install-haproxy-on-client)
    * [Check PXC status](#check-pxc-status)
    * [Backup PXC](#backup-pxc)
    * [Restore PXC](#restore-pxc)
  * [Monitor](#monitor)
  * [Logging](#logging)
  * [Troubleshooting](#troubleshooting)
    * [How to recover PXC cluster](#how-to-recover-pxc-cluster)
  * [Configuring PXC](#configuring-pxc)
    * [Data consistency](#data-consistency)
  * [Testing](#testing)
* [References](#references)

## Supported platforms

- Ubuntu 14.04
- Ubuntu 16.04
- CentOS 7

## Supported MySQL Distributions

- Percona Server Cluster 5.6/5.7

## Development

### Setup

```
vagrant up
```

You can run `export PXC_CLUSTER_NUM=<num>` to specify cluster num.

### Teardown

```
vagrant destroy -f
```

## Operations

### Install PXC on bare metal machines

1) Get mysqlops.

```
sh $ git clone https://github.com/cofyc/mysqlops.git
```

2) Generate passwords.

Please use `uuid` or other tools to generate too passwords for:

- mysql root password: <mysql-root-password>
- pxc sst password: <mysql-sst-password>

#### PXC single-node cluster

```
sh $ mkdir /path/to/mysql
sh $ /path/to/mysqlops/cluster/install-pxc.sh -d /path/to/mysql/data -b <node-ip> -c <node-ip> -p <mysql-root-password> -s <sst-password> -e production bootstrap
```

#### PXC multi-node cluster

Bootstrap cluster on node 1 first:

```
[node1]$ /path/to/mysqlops/cluster/install-pxc.sh -d /path/to/mysql/data -b <node1-ip> -c <node1-ip>,<node2-ip>,<node3-ip> -p <mysql-root-password> -s <sst-password> -e production bootstrap
```

Then install and join other nodes:

```
[node2]$ /path/to/mysqlops/cluster/install-pxc.sh -d /path/to/mysql/data -b <node2-ip> -c <node1-ip>,<node2-ip>,<node3-ip> -p <mysql-root-password> -s <sst-password> -e production
[node3]$ /path/to/mysqlops/cluster/install-pxc.sh -d /path/to/mysql/data -b <node3-ip> -c <node1-ip>,<node2-ip>,<node3-ip> -p <mysql-root-password> -s <sst-password> -e production
```

#### Install HAProxy on client

```
[app1] /path/to/mysqlops/cluster/install-pxc-ha.sh -c <node1-ip>,<node2-ip>,<node3-ip> 
[app2] /path/to/mysqlops/cluster/install-pxc-ha.sh -c <node1-ip>,<node2-ip>,<node3-ip> 
[app3] /path/to/mysqlops/cluster/install-pxc-ha.sh -c <node1-ip>,<node2-ip>,<node3-ip> 
...
```

#### Check PXC Status

```
$ /path/to/mysqlops/cluster/check-pxc-status.sh
```

#### Backup PXC

If you want to backup your mysql to `/backup/mysql`, insert these into `crontab -e`:

```
*/5 * * * * bash /path/to/mysqlops/cluster/backup.sh -d /backup/mysql > /var/log/pxc.backup.log 2>&1
```

### Restore PXC

First, install MySQL packages but don't start it.

```
/etc/init.d/mysql stop # ubuntu 14.04/16.04
systemctl stop mysql|mysql@bootstrap # CentOS 7
```

The, restore MySQL from backup:

```
/path/to/mysqlops/cluster/restore.sh -w /path/to/mysql/data -r /path/to/mysql/backup/incr/2016-03-10_19-18-56/2016-03-10_19-22-30/
```

Start MySQL new restored data set:

```
/etc/init.d/mysql bootstrap-pxc # Ubuntu 14.04/16.04
sytemctl start mysql@bootstrap # CentOS 7
```

Note, for a new cluster, you need start it in bootstrap mode.

### Monitor

See `prometheus/` subdirectory.

### Logging

The install script will generated logrotate script at /etc/logrotate.d/mysql.

### Troubleshooting

#### How to recover PXC cluster

1) For single-node cluster

If single-node cluster crashes, whole cluster is down. So you need to recover
the cluster, please run:

```
/etc/init.d/mysql bootstrap-pxc
```

In production, you need to let the machine to start MySQL in bootstrap mode on
reboot.

2) For multi-nodes cluster

If one of nodes crashes, start mysql to let it join the cluster:

```
/etc/init.d/mysql start
```

### Configuring PXC

#### Data consistency 

By default PXC is asynchronous. To make it fully synchronous, you must enable
`wsrep_sync_wait`.

See https://www.percona.com/doc/percona-xtradb-cluster/5.6/wsrep-system-index.html#wsrep_sync_wait.

### Testing

Before testing, create test database and test user:

```
mysql -e 'CREATE DATABASE clusterup;'
mysql -e 'GRANT ALL ON clusterup.* TO "cu"@"%" IDENTIFIED BY "cu";'
mysql -e "FLUSH PRIVILEGES;"
```

Run tests:

```
$ apt-get install -y sysbench
$ /path/to/mysqlops/cluster/sysbench.sh prepare
$ /path/to/mysqlops/cluster/sysbench.sh run
```

Drop test database and test user if needed:

```
mysql -e 'DROP USER "cu"@"%";'
mysql -e 'DROP DATABASE IF EXISTS clusterup;'
```

## References

- https://github.com/percona/xtradb-cluster-tutorial
- https://www.percona.com/doc/percona-xtradb-cluster/LATEST/howtos/centos_howto.html
- https://www.percona.com/doc/percona-xtradb-cluster/5.6/index.html
- https://www.percona.com/blog/tag/percona-xtradb-cluster/
- https://www.percona.com/blog/2014/09/01/galera-replication-how-to-recover-a-pxc-cluster/
- https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/
- https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/
