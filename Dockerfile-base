FROM php:5.6-apache
MAINTAINER Benjamin Hutchins <ben@hutchins.co>

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
        libpq-dev \
        libzip-dev \
        imagemagick \
        netcat \
    && ln -fs /usr/lib/x86_64-linux-gnu/libzip.so /usr/lib/ \
    && docker-php-ext-install intl zip mbstring opcache fileinfo \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install pgsql \
    && apt-get purge -y --auto-remove g++ libicu-dev libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Installing PEAR modules for Mail to allow MediaWiki to use SMTP for emails
RUN pear install mail net_smtp

# Enable the Apache rewrite module, which is commonly used so you can have
# nicer formatted URLs than /index.php?page=...
RUN a2enmod rewrite

# Add mediawiki deployment keys from https://www.mediawiki.org/keys/keys.txt
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
    441276E9CCD15F44F6D97D18C119E1A64D70938E \
    41B2ABE817ADD3E52BDA946F72BC1C5D23107F8A \
    162432D9E81C1C618B301EECEE1F663462D84F01 \
    1D98867E82982C8FE0ABC25F9B69B3109D3BB7B0 \
    3CEF8262806D3F0B6BA1DBDD7956EE477F901A30 \
    280DB7845A1DCAC92BB5A00A946B02565DC00AA7

COPY php.ini /usr/local/etc/php/conf.d/mediawiki.ini

COPY apache/mediawiki.conf /etc/apache2/
RUN echo "Include /etc/apache2/mediawiki.conf" >> /etc/apache2/apache2.conf

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
