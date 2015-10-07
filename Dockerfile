FROM php:5.6-apache
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

# Waiting in antiticipation for built-time arguments
# https://github.com/docker/docker/issues/14634
ENV MEDIAWIKI_VERSION 1.23.10

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
    && ln -fs /usr/lib/x86_64-linux-gnu/libzip.so /usr/lib/ \
    && docker-php-ext-install intl mysqli zip mbstring opcache fileinfo \
    && apt-get purge -y --auto-remove g++ libicu-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite

# https://www.mediawiki.org/keys/keys.txt
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
    441276E9CCD15F44F6D97D18C119E1A64D70938E \
    41B2ABE817ADD3E52BDA946F72BC1C5D23107F8A \
    162432D9E81C1C618B301EECEE1F663462D84F01 \
    1D98867E82982C8FE0ABC25F9B69B3109D3BB7B0 \
    3CEF8262806D3F0B6BA1DBDD7956EE477F901A30 \
    280DB7845A1DCAC92BB5A00A946B02565DC00AA7

RUN MW_VER_MAJOR_PLUS_MINOR=$(php -r '$parts=explode(".", $_ENV["MEDIAWIKI_VERSION"], 3); echo "{$parts[0]}.{$parts[1]}";'); \
    MEDIAWIKI_DOWNLOAD_URL="https://releases.wikimedia.org/mediawiki/$MW_VER_MAJOR_PLUS_MINOR/mediawiki-$MEDIAWIKI_VERSION.tar.gz"; \
    set -x; \
    mkdir -p /usr/src/mediawiki \
    && curl -fSL "$MEDIAWIKI_DOWNLOAD_URL" -o mediawiki.tar.gz \
    && curl -fSL "${MEDIAWIKI_DOWNLOAD_URL}.sig" -o mediawiki.tar.gz.sig \
    && gpg --verify mediawiki.tar.gz.sig \
    && tar -xf mediawiki.tar.gz -C /usr/src/mediawiki --strip-components=1 \
    && rm -f mediawiki.tar.gz mediawiki.tar.gz.sig

COPY php.ini /usr/local/etc/php/conf.d/mediawiki.ini

COPY apache/mediawiki.conf /etc/apache2/
RUN echo "Include /etc/apache2/mediawiki.conf" >> /etc/apache2/apache2.conf

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
