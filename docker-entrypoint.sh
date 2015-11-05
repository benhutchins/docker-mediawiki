#!/bin/bash

set -e

: ${MEDIAWIKI_SLEEP:=0}

# Sleep because if --link was used, docker-compose, or similar
# we need to give the database time to start up before we try to connect
sleep $MEDIAWIKI_SLEEP

: ${MEDIAWIKI_SITE_NAME:=MediaWiki}
: ${MEDIAWIKI_SITE_LANG:=en}
: ${MEDIAWIKI_ADMIN_USER:=admin}
: ${MEDIAWIKI_ADMIN_PASS:=rosebud}
: ${MEDIAWIKI_DB_TYPE:=mysql}
: ${MEDIAWIKI_DB_SCHEMA:=mediawiki}
: ${MEDIAWIKI_UPDATE:=false}

if [ -z "$MEDIAWIKI_DB_HOST" ]; then
	if [ -n "$DB_PORT_3306_TCP_ADDR" ]; then
		MEDIAWIKI_DB_HOST=$DB_PORT_3306_TCP_ADDR
	elif [ -n "$DB_PORT_5432_TCP_ADDR" ]; then
		MEDIAWIKI_DB_TYPE=postgres
		MEDIAWIKI_DB_HOST=$DB_PORT_5432_TCP_ADDR
	else
		echo >&2 'error: missing MEDIAWIKI_DB_HOST environment variable'
		echo >&2 '	Did you forget to --link your database?'
		exit 1
	fi
fi

if [ -z "$MEDIAWIKI_DB_USER" ]; then
	if [ "$MEDIAWIKI_DB_TYPE" = "mysql" ]; then
		echo >&2 'info: missing MEDIAWIKI_DB_USER environment variable, defaulting to "root"'
		MEDIAWIKI_DB_USER=root
	elif [ "$MEDIAWIKI_DB_TYPE" = "postgres" ]; then
		echo >&2 'info: missing MEDIAWIKI_DB_USER environment variable, defaulting to "postgres"'
		MEDIAWIKI_DB_USER=postgres
	else
		echo >&2 'error: missing required MEDIAWIKI_DB_USER environment variable'
		exit 1
	fi
fi

if [ -z "$MEDIAWIKI_DB_PASSWORD" ]; then
	if [ -n "$DB_ENV_MYSQL_ROOT_PASSWORD" ]; then
		MEDIAWIKI_DB_PASSWORD=$DB_ENV_MYSQL_ROOT_PASSWORD
	elif [ -n "$DB_ENV_POSTGRES_PASSWORD" ]; then
		MEDIAWIKI_DB_PASSWORD=$DB_ENV_POSTGRES_PASSWORD
	else
		echo >&2 'error: missing required MEDIAWIKI_DB_PASSWORD environment variable'
		echo >&2 '	Did you forget to -e MEDIAWIKI_DB_PASSWORD=... ?'
		echo >&2
		echo >&2 '	(Also of interest might be MEDIAWIKI_DB_USER and MEDIAWIKI_DB_NAME)'
		exit 1
	fi
fi

: ${MEDIAWIKI_DB_NAME:=mediawiki}

if [ -z "$MEDIAWIKI_DB_PORT" ]; then
	if [ -n "$DB_PORT_3306_TCP_PORT" ]; then
		MEDIAWIKI_DB_PORT=$DB_PORT_3306_TCP_PORT
	elif [ -n "$DB_PORT_5432_TCP_PORT" ]; then
		MEDIAWIKI_DB_PORT=$DB_PORT_5432_TCP_PORT
	elif [ "$MEDIAWIKI_DB_TYPE" = "mysql" ]; then
		MEDIAWIKI_DB_PORT="3306"
	elif [ "$MEDIAWIKI_DB_TYPE" = "postgres" ]; then
		MEDIAWIKI_DB_PORT="5432"
	fi
fi

export MEDIAWIKI_DB_TYPE MEDIAWIKI_DB_HOST MEDIAWIKI_DB_USER MEDIAWIKI_DB_PASSWORD MEDIAWIKI_DB_NAME

TERM=dumb php -- <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

if ($_ENV['MEDIAWIKI_DB_TYPE'] == 'mysql') {

	$mysql = new mysqli($_ENV['MEDIAWIKI_DB_HOST'], $_ENV['MEDIAWIKI_DB_USER'], $_ENV['MEDIAWIKI_DB_PASSWORD'], '', (int) $_ENV['MEDIAWIKI_DB_PORT']);

	if ($mysql->connect_error) {
		file_put_contents('php://stderr', 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		exit(1);
	}

	if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($_ENV['MEDIAWIKI_DB_NAME']) . '`')) {
		file_put_contents('php://stderr', 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
		$mysql->close();
		exit(1);
	}

	$mysql->close();
}
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

if [ -d "/data" ]; then
	# If there is no LocalSettings.php but we have one under the shared
	# directory, symlink it
	if [ -e "/data/LocalSettings.php" -a ! -e LocalSettings.php ]; then
		ln -s "/data/LocalSettings.php" LocalSettings.php
	fi

	# If the images directory only contains a README, then link it to
	# /data/images, creating the shared directory if necessary
	if [ "$(ls images)" = "README" -a ! -L images ]; then
		rm -fr images
		mkdir -p "/data/images"
		ln -s "/data/images" images
	fi

	# If an extensions folder exists inside the shared directory, as long as
	# /var/www/html/extensions is not already a symbolic link, then replace it
	if [ -d "/data/extensions" -a ! -h /var/www/html/extensions ]; then
		echo >&2 "Found 'extensions' folder in data volume, creating symbolic link."
		rm -rf /var/www/html/extensions
		ln -s "/data/extensions" /var/www/html/extensions
	fi

	# If a skins folder exists inside the shared directory, as long as
	# /var/www/html/skins is not already a symbolic link, then replace it
	if [ -d "/data/skins" -a ! -h /var/www/html/skins ]; then
		echo >&2 "Found 'skins' folder in data volume, creating symbolic link."
		rm -rf /var/www/html/skins
		ln -s "/data/skins" /var/www/html/skins
	fi

	# If a vendor folder exists inside the shared directory, as long as
	# /var/www/html/vendor is not already a symbolic link, then replace it
	if [ -d "/data/vendor" -a ! -h /var/www/html/vendor ]; then
		echo >&2 "Found 'vendor' folder in data volume, creating symbolic link."
		rm -rf /var/www/html/vendor
		ln -s "/data/vendor" /var/www/html/vendor
	fi

	# Attempt to enable SSL support if explicitly requested
	if [ -e "/data/ssl.key" -a -e "/data/ssl.crt" ]; then
		echo >&2 'info: enabling ssl'
		a2enmod ssl
	elif [ -e "/etc/apache2/mods-enabled/ssl.load" ]; then
		echo >&2 'warning: disabling ssl'
		a2dismod ssl
	fi
fi

# If there is no LocalSettings.php, create one using maintenance/install.php
if [ ! -e "LocalSettings.php" -a ! -z "$MEDIAWIKI_SITE_SERVER" ]; then
	php maintenance/install.php \
		--confpath /var/www/html \
		--dbname "$MEDIAWIKI_DB_NAME" \
		--dbschema "$MEDIAWIKI_DB_SCHEMA" \
		--dbport "$MEDIAWIKI_DB_PORT" \
		--dbserver "$MEDIAWIKI_DB_HOST" \
		--dbtype "$MEDIAWIKI_DB_TYPE" \
		--dbuser "$MEDIAWIKI_DB_USER" \
		--dbpass "$MEDIAWIKI_DB_PASSWORD" \
		--installdbuser "$MEDIAWIKI_DB_USER" \
		--installdbpass "$MEDIAWIKI_DB_PASSWORD" \
		--server "$MEDIAWIKI_SITE_SERVER" \
		--scriptpath "" \
		--lang "$MEDIAWIKI_SITE_LANG" \
		--pass "$MEDIAWIKI_ADMIN_PASS" \
		"$MEDIAWIKI_SITE_NAME" \
		"$MEDIAWIKI_ADMIN_USER"

		# If we have a mounted share volume, move the LocalSettings.php to it
		# so it can be restored if this container needs to be reinitiated
		if [ -d "/data" ]; then
			# Append inclusion of /data/CustomSettings.php
			if [ -e "/data/CustomSettings.php" ]; then
				chown www-data: "/data/CustomSettings.php"
				echo "include('/data/CustomSettings.php');" >> LocalSettings.php
			fi

			# Move generated LocalSettings.php to share volume
			mv LocalSettings.php "/data/LocalSettings.php"
			ln -s "/data/LocalSettings.php" LocalSettings.php
		fi
fi

# If a composer.lock and composer.json file exist, use them to install
# dependencies for MediaWiki and desired extensions, skins, etc.
if [ -e "/data/composer.lock" -a -e "/data/composer.json" ]; then
	curl -sS https://getcomposer.org/installer | php
	cp "/data/composer.lock" composer.lock
	cp "/data/composer.json" composer.json
	php composer.phar install --no-dev
fi

# If LocalSettings.php exists, then attempt to run the update.php maintenance
# script. If already up to date, it won't do anything, otherwise it will
# migrate the database if necessary on container startup. It also will
# verify the database connection is working.
if [ -e "LocalSettings.php" -a $MEDIAWIKI_UPDATE = true ]; then
	echo >&2 'info: Running maintenance/update.php';
	php maintenance/update.php --quick
fi

# Ensure images folder exists
mkdir -p images

# Fix file ownership and permissions
chown -R www-data: .
chmod 755 images

exec "$@"
