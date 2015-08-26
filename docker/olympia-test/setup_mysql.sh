#!/bin/bash
set -ex

install_mysql() {
    # From the mysql Dockerfile.
    # All of this seems decidedly unnecessary...

    apt-get install -y --no-install-recommends \
        perl

    # gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
    apt-key adv --keyserver ha.pool.sks-keyservers.net \
                --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

    echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-${MYSQL_MAJOR}" \
        >/etc/apt/sources.list.d/mysql.list

    apt-get update

    # the "/var/lib/mysql" stuff here is because the mysql-server postinst
    # doesn't have an explicit way to disable the mysql_install_db codepath
    # besides having a database already "configured" (ie, stuff in
    # /var/lib/mysql/mysql)

    # also, we set debconf keys to make APT a little quieter
    {
        echo mysql-community-server mysql-community-server/data-dir select '';
        echo mysql-community-server mysql-community-server/root-pass password '';
        echo mysql-community-server mysql-community-server/re-root-pass password '';
        echo mysql-community-server mysql-community-server/remove-test-db select false;
    } | debconf-set-selections

    rm -rf /var/lib/mysql

    apt-get install -y \
        mysql-server="${MYSQL_VERSION}*"

    rm -rf /var/lib/mysql
    mkdir -p /var/lib/mysql

    # comment out a few problematic configuration values
    # don't reverse lookup hostnames, they are usually another container

    sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf

    awk '//; $1 == "[mysqld]" { print "skip-host-cache"; print "skip-name-resolve" }' \
         </etc/mysql/my.cnf \
         >/tmp/my.cnf

    mv /tmp/my.cnf /etc/mysql/my.cnf

    chown -R mysql:mysql $MYSQL_VOLUME
    mysql_install_db --user=mysql --datadir="$MYSQL_VOLUME" --rpm --keep-my-cnf

    mysqld --user=mysql --datadir="$MYSQL_VOLUME" --skip-networking &
    pid="$!"

    mysql_() {
        mysql --protocol=socket -uroot "$@"
    }

    for i in {30..0}; do
        if echo 'SELECT 1' | mysql_; then
            break
        fi
        echo 'MySQL init process in progress...'
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi

    # sed is for https://bugs.mysql.com/bug.php?id=20545
    mysql_tzinfo_to_sql /usr/share/zoneinfo |
        sed 's/Local time zone must be set--see zic manual page/FCTY/' |
        mysql_ mysql

    mysql_ <<-EOSQL
        -- What's done in this file shouldn't be replicated
        --  or products like mysql-fabric won't work
        SET @@SESSION.SQL_LOG_BIN=0;

        DELETE FROM mysql.user ;
        CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
        GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
        DROP DATABASE IF EXISTS test ;
        FLUSH PRIVILEGES ;

        CREATE DATABASE IF NOT EXISTS `$MYSQL_DATABASE`;
EOSQL

    kill -TERM "$pid"
    wait "$pid"

    chown -R mysql:mysql $MYSQL_VOLUME
}

install_mysql

rm -rf /etc/apt/sources.list.d/*
rm -rf /var/lib/apt/lists/* 
