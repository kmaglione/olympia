#!/bin/sh
set -ex

arch="$(dpkg --print-architecture)"
curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch"
curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch.asc"

gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
gpg --verify /usr/local/bin/gosu.asc

rm /usr/local/bin/gosu.asc
chmod +x /usr/local/bin/gosu

apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4
echo "deb http://packages.elasticsearch.org/elasticsearch/$ELASTICSEARCH_MAJOR/debian stable main" > /etc/apt/sources.list.d/elasticsearch.list

apt-get update
apt-get install -y --no-install-recommends \
	openjdk-7-jre-headless \
	elasticsearch=$ELASTICSEARCH_VERSION

apt-get clean
rm -rf /etc/apt/sources.list.d/*
rm -rf /var/lib/apt/lists/*
