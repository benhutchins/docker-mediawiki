FROM php:5.6-apache
MAINTAINER Synctree App Force <appforce+docker@synctree.com>

ENV MW_VERSION 1.23
ENV MW_FULL_VERSION 1.23.5

WORKDIR /
RUN rm -rf /var/www/html && mkdir /var/www/html
WORKDIR /var/www/html

RUN mkdir -p /usr/src/mediawiki && \
    curl -sSL https://releases.wikimedia.org/mediawiki/$MW_VERSION/mediawiki-$MW_FULL_VERSION.tar.gz | \
    tar --strip-components=1 -xzC /usr/src/mediawiki

RUN a2enmod rewrite

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2", "-DFOREGROUND"]
