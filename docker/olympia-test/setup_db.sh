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

export DJANGO_SETTINGS_MODULE=settings_test
python manage.py reset_db --noinput
python manage.py syncdb --noinput

HIGHEST_MIGRATION=$(cd migrations; \
                    ls | sort -rn | sed -n 's/^\([0-9]\+\).*/\1/p' | head -1)
schematic -u $HIGHEST_MIGRATION migrations

rm -rf * .* || true

kill -TERM $mysqld
wait
