# What is MediaWiki?

MediaWiki is a free and open-source wiki app, used to power wiki websites such
as Wikipedia, Wiktionary and Commons, developed by the Wikimedia Foundation and
others.

> [wikipedia.org/wiki/MediaWiki](https://en.wikipedia.org/wiki/MediaWiki)

# How to use this image

    docker run --name some-mediawiki --link some-mysql:mysql -v /local/data/path:/data:rw -d benhutchins/mediawiki

Partial explanation of arguments:

 - `--link` allows you to connect this container with a database container. See `Configure Database` below for more details.
 - `-v` is used to mount a shared folder with the container. If provided, you can place your `LocalSettings.php` inside this folder. All files and images uploaded to the wiki will also be placed within an `images` folder of this shared volume. By default the shared bath must be mounted to `/data` on the container, you can change this using by using `-e MEDIAWIKI_SHARED=/new/data/path`.

 Having troubling accessing your MediaWiki server? See `Accessing MediaWiki` below for help.

## Specify MediaWiki version

To specify the version of MediaWiki you'd like to install, use `-e MEDIAWIKI_VERSION=1.25.2`. As of writing this, `1.25.2` was the latest stable release. Or you can use one of the built containers using that version:

 - `benhutchins/mediawiki:1.23` (uses `1.23.10`, official Long Term Support by [MediaWiki](https://www.mediawiki.org/wiki/MediaWiki))
 - `benhutchins/mediawiki:1.24` (uses `1.24.3`)
 - `benhutchins/mediawiki:1.25` (uses `1.25.2`)
 - `benhutchins/mediawiki:latest` (currently uses `1.25.2`)
 - `benhutchins/mediawiki:postgres` (currently uses `1.25.2`, and installs the `postgres` php module)

To use one of these pre-built containers, simply specify the tag as part of the `docker run` command:

    docker run --name some-mediawiki --link some-postgres:postgres -v /local/data/path:/data:rw -d benhutchins/mediawiki:postgres

## Docker Compose

To run with [Docker Compose](https://docs.docker.com/compose/install/), you'll need to clone this repository and run:

    docker-compose up

Currently the `docker-compose.yml` is configured to run against `Dockerfile`, which means that it will install MediaWiki version `1.25.2`.

**Note** You'll likely want to uncomment the `docker-compose.yml` file's `volume` lines.

## Configure Database

The example above uses `--link` to connect the MediaWiki container with a running [mysql](https://hub.docker.com/_/mysql/) container. This is probably not the best idea for use in production, keeping data in docker containers can be dangerous.

### Using Postgres

You can use Postgres instead of MySQL as your database server using the `:latest-postgres` tag:

    docker run --name some-mediawiki --link some-postgres:postgres -v /local/data/path:/data:rw -d benhutchins/mediawiki:postgres

### Using Database Server

You can use the following environment variables for connecting to another database server:

 - `-e MEDIAWIKI_DB_TYPE=...` (defaults to `mysql`, but can also be `postgres`)
 - `-e MEDIAWIKI_DB_HOST=...` (defaults to the address of the linked database container)
 - `-e MEDIAWIKI_DB_PORT=...` (defaults to the port of the linked database container)
 - `-e MEDIAWIKI_DB_USER=...` (defaults to "root")
 - `-e MEDIAWIKI_DB_PASSWORD=...` (defaults to the password of the linked mysql container)
 - `-e MEDIAWIKI_DB_NAME=...` (defaults to "mediawiki")

If the `MEDIAWIKI_DB_NAME` specified does not already exist on the provided MySQL
server, it will be created automatically upon container startup, provided
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

After using the installation wizard, save a copy of the generated `LocalSettings.php` to your data volume (`-v /local/data/dir:/data:rw`).

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
