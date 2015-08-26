#!/bin/sh
set -x

mysqld &
mysqld=$!

elasticsearch -d -D es.path.data=/tmp -D es.gateway.type=none -D es.index.store.type=memory -D es.discovery.zen.ping.multicast.enabled=false &
elasticsearch=$!

export ELASTICSEARCH_LOCATION=localhost:9200

cd /code

git clone --depth 1 --branch "$GITHUB_BRANCH" "$GITHUB_HEAD_REPO_URL" ./

python manage.py update_product_details
py.test -n $NUM_WORKERS
result=$?

kill -TERM $mysqld
kill -TERM $elasticsearch

exit $result
