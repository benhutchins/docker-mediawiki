FROM php:5.6-apache
MAINTAINER Synctree App Force <appforce+docker@synctree.com>

ENV MEDIAWIKI_VERSION 1.23
ENV MEDIAWIKI_FULL_VERSION 1.23.6

WORKDIR /
RUN rm -rf /var/www/html && mkdir /var/www/html
WORKDIR /var/www/html

RUN docker-php-ext-install mysqli

RUN mkdir -p /usr/src/mediawiki && \
    curl -sSL https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_VERSION/mediawiki-$MEDIAWIKI_FULL_VERSION.tar.gz | \
    tar --strip-components=1 -xzC /usr/src/mediawiki

RUN a2enmod rewrite

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2", "-DFOREGROUND"]
