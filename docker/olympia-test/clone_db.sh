#!/bin/sh
set -ex

mysqld \
    --skip-innodb_doublewrite \
    --transaction_prealloc_size=$((16 * 1024 * 1024)) \
    --innodb_flush_log_at_trx_commit=2 \
    --innodb_flush_method=nosync &
mysqld=$!

cd /code
git clone --depth 1 --branch "$GITHUB_BRANCH" "$GITHUB_HEAD_REPO_URL" ./

mysqldump $MYSQL_DATABASE >olympia.sql

for i in $(seq 0 $NUM_WORKERS)
do
    db=test_${MYSQL_DATABASE}_gw$i
    mysqladmin create $db
    mysql $db <olympia.sql
done

rm -rf * .* || true

kill -TERM $mysqld
wait
