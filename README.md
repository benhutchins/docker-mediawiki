# What is MediaWiki?

MediaWiki is a free and open-source wiki app, used to power wiki websites such
as Wikipedia, Wiktionary and Commons, developed by the Wikimedia Foundation and
others.

> [wikipedia.org/wiki/MediaWiki](https://en.wikipedia.org/wiki/MediaWiki)

# How to use this image

	docker run --name some-mediawiki --link some-mysql:mysql -d synctree/mediawiki

The following environment variables are also honored for configuring your
MediaWiki instance:

 - `-e MEDIAWIKI_DB_USER=...` (defaults to "root")
 - `-e MEDIAWIKI_DB_PASSWORD=...` (defaults to the value of the
   `MYSQL_ROOT_PASSWORD` environment variable from the linked mysql container)
 - `-e MEDIAWIKI_DB_NAME=...` (defaults to "mediawiki")

If the `MEDIAWIKI_DB_NAME` specified does not already exist in the given MySQL
container,  it will be created automatically upon container startup, provided
that the `MEDIAWIKI_DB_USER` specified has the necessary permissions to create
it.

If you'd like to be able to access the instance from the host without the
container's IP, standard port mappings can be used:

    docker run --name some-mediawiki --link some-mysql:mysql -p 8080:80 -d synctree/mediawiki

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser.
