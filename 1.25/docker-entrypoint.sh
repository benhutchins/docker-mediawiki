#!/bin/bash

set -e

: ${MEDIAWIKI_SITE_NAME:=MediaWiki}

if [ -z "$MEDIAWIKI_DB_HOST" ]; then
	if [ -n "$MYSQL_PORT_3306_TCP_ADDR" ]; then
		: ${MEDIAWIKI_DB_HOST:=${MYSQL_PORT_3306_TCP_ADDR}}
	elif [ -n "$DB_PORT_3306_TCP_ADDR" ]; then
		: ${MEDIAWIKI_DB_HOST:=${DB_PORT_3306_TCP_ADDR}}
	else
		echo >&2 'error: missing MEDIAWIKI_DB_HOST environment variable'
		echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
		exit 1
	fi
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${MEDIAWIKI_DB_USER:=root}
if [ "$MEDIAWIKI_DB_USER" = 'root' -a -z "$MEDIAWIKI_DB_PASSWORD" ]; then
	if [ -n "$MYSQL_ENV_MYSQL_ROOT_PASSWORD" ]; then
		: ${MEDIAWIKI_DB_PASSWORD:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD}}
	elif [ -n "$DB_ENV_MYSQL_ROOT_PASSWORD" ]; then
		: ${MEDIAWIKI_DB_PASSWORD:=${DB_ENV_MYSQL_ROOT_PASSWORD}}
	fi
fi

if [ -z "$MEDIAWIKI_DB_PASSWORD" ]; then
	echo >&2 'error: missing required MEDIAWIKI_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e MEDIAWIKI_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be MEDIAWIKI_DB_USER and MEDIAWIKI_DB_NAME.)'
	exit 1
fi

: ${MEDIAWIKI_DB_NAME:=mediawiki}

if [ -z "$MEDIAWIKI_DB_PORT" ]; then
	if [ -n "$MYSQL_PORT_3306_TCP_PORT" ]; then
		: ${MEDIAWIKI_DB_PORT:=${MYSQL_PORT_3306_TCP_PORT}}
	elif [ -n "$DB_PORT_3306_TCP_PORT" ]; then
		: ${MEDIAWIKI_DB_PORT:=${DB_PORT_3306_TCP_PORT}}
	fi
fi

TERM=dumb php -- "$MEDIAWIKI_DB_HOST" "$MEDIAWIKI_DB_PORT" "$MEDIAWIKI_DB_USER" "$MEDIAWIKI_DB_PASSWORD" "$MEDIAWIKI_DB_NAME" <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

print_r($_ENV);
print_r($argv);

$DB_HOST = $argv[1];
$DB_PORT = $argv[2];
$DB_USER = $argv[3];
$DB_PASS = $argv[4];
$DB_NAME = $argv[5];

$mysql = new mysqli($DB_HOST, $DB_USER, $DB_PASS, '', (int) $DB_PORT);

if ($mysql->connect_error) {
	file_put_contents('php://stderr', 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
	exit(1);
}

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($DB_NAME) . '`')) {
	file_put_contents('php://stderr', 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

$mysql->close();
EOPHP

if ! [ -e index.php -a -e includes/DefaultSettings.php ]; then
	echo >&2 "MediaWiki not found in $(pwd) - copying now..."

	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	tar cf - --one-file-system -C /usr/src/mediawiki . | tar xf -
	echo >&2 "Complete! MediaWiki has been successfully copied to $(pwd)"
fi

: ${MEDIAWIKI_SHARED:=/var/www-shared/html}
if [ -d "$MEDIAWIKI_SHARED" ]; then
	# If there is no LocalSettings.php but we have one under the shared
	# directory, symlink it
	if [ -e "$MEDIAWIKI_SHARED/LocalSettings.php" -a ! -e LocalSettings.php ]; then
		cp "$MEDIAWIKI_SHARED/LocalSettings.php" LocalSettings.php
		# We need to copy it, instead of symlink because file permisisons break
		# when trying to use Docker Machine
	fi

	# If the images directory only contains a README, then link it to
	# $MEDIAWIKI_SHARED/images, creating the shared directory if necessary
	if [ "$(ls images)" = "README" -a ! -L images ]; then
		rm -fr images
		mkdir -p "$MEDIAWIKI_SHARED/images"
		ln -s "$MEDIAWIKI_SHARED/images" images
	fi
fi

chown -R www-data: .

export MEDIAWIKI_SITE_NAME MEDIAWIKI_DB_HOST MEDIAWIKI_DB_USER MEDIAWIKI_DB_PASSWORD MEDIAWIKI_DB_NAME

exec "$@"
