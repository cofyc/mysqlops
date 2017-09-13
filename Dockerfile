FROM ubuntu:16.04

# Set timezone to Asia/Shanghai.
RUN set -x \
	&& cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
	&& echo "Asia/Shanghai" > /etc/timezone \
    && sed -i /security.ubuntu.com/d /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y percona-toolkit \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ADD cluster /mysqlops/cluster
