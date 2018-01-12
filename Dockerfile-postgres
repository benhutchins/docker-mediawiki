FROM benhutchins/mediawiki:nodb
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

# We use docker-php-ext-install to enable PHP modules,
# @see https://github.com/docker-library/php/blob/master/docker-php-ext-install
# Uses phpize underneath instead of perl.
RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        libpq-dev \
    && docker-php-ext-install pgsql \
    && rm -rf /var/lib/apt/lists/*
