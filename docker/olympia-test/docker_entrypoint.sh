#!/bin/sh
set -ex

# Run MySQL without many of the features required only for crash tolerance.
# We have no use for crash tolerance, since we just throw away the DB in
# the case of failure, and turning them off significantly shortens the runtime
# of tests.
mysqld \
    --sync_binlog=0 \
    --skip-innodb_doublewrite \
    --transaction_prealloc_size=$((16 * 1024 * 1024)) \
    --innodb_write_io_threads=8 \
    --innodb_purge_threads=8 \
    --innodb_io_capacity=400 \
    --innodb_flush_log_at_trx_commit=2 \
    --innodb_flush_method=nosync \
    --innodb_log_file_size=512M \
    --innodb_buffer_pool_size=$((2 * 1024 * 1024 * 1024)) &
mysqld=$!

mkdir /tmp/es_data /tmp/es_logs
elasticsearch -d \
    -D es.default.config=/etc/elasticsearch/elasticsearch.yml \
    -D es.path.conf=/etc/elasticsearch/ \
    -D es.path.logs=/tmp/es_logs \
    -D es.path.data=/tmp/es_data \
    -D es.gateway.type=none \
    -D es.index.store.type=memory \
    -D es.discovery.zen.ping.multicast.enabled=false &

git clone --depth 1 --branch "$GITHUB_HEAD_BRANCH" "$GITHUB_HEAD_REPO_URL" ./

(cd /pip; sh pip_install.sh install -r /code/requirements/docker.txt)

if "$@"
then result=0
else result=$?
fi

kill -TERM $mysqld
killall java

exit $result
