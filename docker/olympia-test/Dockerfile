FROM kmaglione/olympia-base:latest

ENV MYSQL_VOLUME=/var/lib/mysql \
    MYSQL_ROOT_PASSWORD= \
    MYSQL_DATABASE=olympia \
    MYSQL_MAJOR=5.6 \
    MYSQL_VERSION=5.6.26 \
    MYSQL_ALLOW_EMPTY_PASSWORD=yes \
    ELASTICSEARCH_MAJOR=1.3 \
    ELASTICSEARCH_VERSION=1.3.9 \
    PATH=/usr/share/elasticsearch/bin:$PATH

ENV GITHUB_BRANCH=docker_tests \
    GITHUB_HEAD_REPO_URL=https://github.com/kmaglione/olympia \
    ELASTICSEARCH_LOCATION=localhost:9200 \
    DATABASE_URL=mysql://root:$MYSQL_ROOT_PASSWORD@localhost:3306/$MYSQL_DATABASE \
    NUM_WORKERS=8 \
    RUNNING_IN_CI=True


COPY setup_mysql.sh /init/
RUN cd /init && bash setup_mysql.sh

COPY setup_elasticsearch.sh /init/
RUN cd /init && sh setup_elasticsearch.sh

COPY setup_db.sh /init/
RUN cd /init && sh setup_db.sh

COPY clone_db.sh /init/
RUN cd /init && sh clone_db.sh

WORKDIR /code

VOLUME $MYSQL_VOLUME
VOLUME /usr/share/elasticsearch/data

COPY docker_entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["sh", "-c", "py.test -n $NUM_WORKERS"]
