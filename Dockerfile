FROM debian:jessie

RUN mkdir /code

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        libjpeg62-turbo \
        libmysqlclient18 \
        libopenjpeg5 \
        libpng12-0 \
        libsasl2-2 \
        libssl1.0.0 \
        libxml2 \
        libxslt1.1 \
        make \
        mysql-client \
        nodejs \
        python-pip \
        wget \
        zlib1g \
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

ENV DEPS_M2CRYPTO="swig libssl-dev dpkg-dev" \
    DEPS_PILLOW="libjpeg-dev libopenjpeg-dev libpng-dev zlib1g-dev" \
    DEPS_MYSQL="libmysqlclient-dev"

RUN deps=" \
        g++ \
	${DEPS_M2CRYPTO} \
	${DEPS_PILLOW} \
        ${DEPS_MYSQL} \
        libsasl2-dev \
        libxml2-dev \
        libxslt-dev \
        python-dev \
    "; \
    cd /pip && \
    apt-get install -y --no-install-recommends $deps && \
    sh pip_install.sh wheel --wheel-dir=./wheels \
        -r requirements/docker-git.txt && \
    sh pip_install.sh wheel --wheel-dir=./wheels \
        -r requirements/docker-build.txt && \
    apt-get purge -y --auto-remove $deps && \
    apt-get clean && \
    rm -rf build cache/http

WORKDIR /code
