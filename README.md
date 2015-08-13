# What is MediaWiki?

MediaWiki is a free and open-source wiki app, used to power wiki websites such
as Wikipedia, Wiktionary and Commons, developed by the Wikimedia Foundation and
others.

> [wikipedia.org/wiki/MediaWiki](https://en.wikipedia.org/wiki/MediaWiki)

# How to use this image

    docker run --name some-mediawiki --link some-mysql:mysql -v ./shared:/var/www-shared/html:rw -d benhutchins/mediawiki

## Specify MediaWiki version

To specify the version of MediaWiki you'd like to use, set both `MEDIAWIKI_VERSION` and `MEDIAWIKI_FULL_VERSION`.

    -e MEDIAWIKI_VERSION=1.25
    -e MEDIAWIKI_FULL_VERSION=1.25.2

## Docker Compose

To run with [Docker Compose](https://docs.docker.com/compose/install/), you'll need to clone this repository and run:

    docker-compose up

**Note** When using Docker Machine or boot2docker, you'll need to use an absolute path for the `shared` folder. Like:

    docker run \
        --name some-mediawiki \
        --link some-mysql:mysql \
        -v /Users/me/docker-mediawiki/1.25/shared/:/var/www-shared/html:rw \
        benhutchins/mediawiki

## Configure Database

The following environment variables are also honored for configuring your
MediaWiki instance:

 - `-e MEDIAWIKI_DB_HOST=...` (defaults to the address of the linked database container)
 - `-e MEDIAWIKI_DB_PORT=...` (defaults to the port of the linked database container)
 - `-e MEDIAWIKI_DB_USER=...` (defaults to "root")
 - `-e MEDIAWIKI_DB_PASSWORD=...` (defaults to the password of the linked mysql container)
 - `-e MEDIAWIKI_DB_NAME=...` (defaults to "mediawiki")

If the `MEDIAWIKI_DB_NAME` specified does not already exist in the given MySQL
container,  it will be created automatically upon container startup, provided
that the `MEDIAWIKI_DB_USER` specified has the necessary permissions to create
it.

To use with an external database server, use `MEDIAWIKI_DB_HOST` (along with
`MEDIAWIKI_DB_USER` and `MEDIAWIKI_DB_PASSWORD` if necessary):

    docker run --name some-mediawiki \
        -e MEDIAWIKI_DB_HOST=10.0.0.1
        -e MEDIAWIKI_DB_PORT=3306 \
        -e MEDIAWIKI_DB_USER=app \
        -e MEDIAWIKI_DB_PASSWORD=secure \
        benhutchins/mediawiki

## Accessing MediaWiki

If you'd like to be able to access the instance from the host without the
container's IP, standard port mappings can be used:

    docker run --name some-mediawiki --link some-mysql:mysql -p 8080:80 -d benhutchins/mediawiki

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser.

### Docker Machine

If you're using Docker Machine, using `http://localhost:8080` won't work, instead you'll need to run:

    docker-machine ip default

And access your instance of MediaWiki at:

    http://$(docker-machine ip default):8080/

### boot2docker

If you're using boot2docker, using `http://localhost:8080` won't work, instead you'll need to run:

    boot2docker ip

And access your instance of MediaWiki at:

    http://$(boot2docker ip):8080/
