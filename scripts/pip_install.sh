#!/bin/sh

pip install --no-cache-dir -U pip wheel

# Pip's HTTP caching does not work very well, and it tends to fetch a new copy
# of both of these for every package it installs, so pre-downloading a local
# copy actually saves a considerable amount of time.

wget -nv -k -O pyrepo.html https://pyrepo.addons.mozilla.org/
wget -nv -k -O wheelhouse.html https://pyrepo.addons.mozilla.org/wheelhouse/

cmd=$1; shift

exec pip $cmd --no-index \
	--no-deps \
	--build ./build \
	--cache-dir ./cache \
	--find-links ./wheels \
	--find-links pyrepo.html \
	--find-links wheelhouse.html \
	"$@"
