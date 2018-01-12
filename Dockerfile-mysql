FROM benhutchins/mediawiki:nodb
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

# We use docker-php-ext-install to enable PHP modules,
# @see https://github.com/docker-library/php/blob/master/docker-php-ext-install
# Uses phpize underneath instead of perl.
RUN set -x; \
    apt-get update \
    && docker-php-ext-install mysqli \
    && rm -rf /var/lib/apt/lists/*
