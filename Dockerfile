FROM php:5.6-apache
MAINTAINER Synctree App Force <appforce+docker@synctree.com>

ENV MEDIAWIKI_VERSION 1.23
ENV MEDIAWIKI_FULL_VERSION 1.23.7

WORKDIR /
RUN rm -rf /var/www/html && mkdir /var/www/html
WORKDIR /var/www/html

RUN apt-get update && \
    apt-get install -y g++ libicu-dev && \
    rm -rf /var/run/apt/lists/*

RUN docker-php-ext-install mysqli opcache

RUN pecl install intl && \
    echo extension=intl.so >> /usr/local/etc/php/conf.d/ext-intl.ini

RUN a2enmod rewrite

RUN mkdir -p /usr/src/mediawiki && \
    curl -sSL https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/mediawiki-$MEDIAWIKI_FULL_VERSION.tar.gz | \
    tar --strip-components=1 -xzC /usr/src/mediawiki

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2", "-DFOREGROUND"]
