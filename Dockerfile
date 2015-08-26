FROM debian:jessie

RUN mkdir /code

ENV DEPS_HIVE="libsasl2-2" \
    DEPS_LXML="libxml2 libxslt1.1" \
    DEPS_M2CRYPTO="libssl1.0.0" \
    DEPS_MYSQL="libmysqlclient18" \
    DEPS_PILLOW="libjpeg62-turbo libopenjpeg5 libpng12-0 zlib1g"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ${DEPS_HIVE} \
        ${DEPS_LXML} \
        ${DEPS_M2CRYPTO} \
        ${DEPS_MYSQL} \
        ${DEPS_PILLOW} \
        curl \
        git \
        make \
        mysql-client \
        nodejs \
        python-pip \
        wget \
        && \
    apt-get clean

# Create a virtualenv for all of our packages, so
# we can install things without conflicting with
# system packages.
RUN pip install virtualenv && \
    virtualenv /virtualenv && \
    echo . /virtualenv/bin/activate >/etc/profile.d/virtualenv.sh && \
    . /virtualenv/bin/activate && \
    pip install -U pip wheel

# Use our virtualenv for the rest of our commands.
ENV PATH=/virtualenv/bin:$PATH

COPY scripts/pip_install.sh /pip/
COPY requirements /pip/requirements/

# Build and cache the base set of requirements so initial setup
# is as quick as possible for developers, but we don't have
# pre-installed packages for dependencies which may have changed.

# Install system build dependencies prior to build, and uninstall them after,
# in the same RUN step so that we don't needlessly bloat the image or its
# intermediates.

ENV DEPS_HIVE="libsasl2-dev" \
    DEPS_LXML="libxml2-dev libxslt-dev" \
    DEPS_M2CRYPTO="swig libssl-dev dpkg-dev" \
    DEPS_MYSQL="libmysqlclient-dev" \
    DEPS_PILLOW="libjpeg-dev libopenjpeg-dev libpng-dev zlib1g-dev"

RUN deps=" \
        g++ \
        ${DEPS_HIVE} \
        ${DEPS_LXML} \
        ${DEPS_M2CRYPTO} \
        ${DEPS_MYSQL} \
        ${DEPS_PILLOW} \
        python-dev \
    "; \
    cd /pip && \
        \
    apt-get update && \
    apt-get install -y --no-install-recommends $deps && \
        \
    sed -n 's/^# \(git+.*\)/\1/p' <requirements/git.txt >requirements/docker-git.txt && \
    sh pip_install.sh wheel --wheel-dir=./wheels \
        -r requirements/docker-git.txt && \
        \
    sh pip_install.sh wheel --wheel-dir=./wheels \
        -r requirements/docker-build.txt && \
        \
    apt-get purge -y --auto-remove $deps && \
    apt-get clean && \
    rm -rf build cache/http

WORKDIR /code
