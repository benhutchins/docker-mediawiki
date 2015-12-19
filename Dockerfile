# TODO: Switch to debian sid

FROM php:5.6-apache
MAINTAINER Gabriel Wicke <gwicke@wikimedia.org>

# Waiting in antiticipation for built-time arguments
# https://github.com/docker/docker/issues/14634
ENV MEDIAWIKI_VERSION wmf/1.27.0-wmf.9

# Add EXPOSE 443 because the php:apache only has EXPOSE 80
EXPOSE 80 443

# We use docker-php-ext-install to enable PHP modules,
# @see https://github.com/docker-library/php/blob/master/docker-php-ext-install
# Uses phpize underneath instead of perl.
RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        g++ \
        libicu52 \
        libicu-dev \
        libzip-dev \
        imagemagick \
        netcat \
        git \
    && ln -fs /usr/lib/x86_64-linux-gnu/libzip.so /usr/lib/ \
    && docker-php-ext-install intl mysqli zip mbstring opcache fileinfo \
    && apt-get purge -y --auto-remove g++ libicu-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && a2enmod rewrite


# MediaWiki setup
RUN set -x; \
    mkdir -p /usr/src \
    && git clone \
        --depth 1 \
        -b $MEDIAWIKI_VERSION \
        https://gerrit.wikimedia.org/r/p/mediawiki/core.git \
        /usr/src/mediawiki \
    && cd /usr/src/mediawiki \
    && git submodule update --init skins \
    && git submodule update --init vendor \
    && cd extensions \
    # VisualEditor
    # TODO: make submodules shallow clones?
    && git submodule update --init VisualEditor \
    && cd VisualEditor \
    && git checkout $MEDIAWIKI_VERSION \
    && git submodule update --init

COPY php.ini /usr/local/etc/php/conf.d/mediawiki.ini

COPY apache/mediawiki.conf /etc/apache2/
RUN echo "Include /etc/apache2/mediawiki.conf" >> /etc/apache2/apache2.conf

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
