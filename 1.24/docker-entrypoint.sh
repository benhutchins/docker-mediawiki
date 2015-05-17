#!/bin/bash

set -e

: ${MEDIAWIKI_SITE_NAME:=MediaWiki}

if [ -z "$MEDIAWIKI_DB_HOST" -a -z "$MYSQL_PORT_3306_TCP" ]; then
	echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
	exit 1
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${MEDIAWIKI_DB_USER:=root}
if [ "$MEDIAWIKI_DB_USER" = 'root' ]; then
	: ${MEDIAWIKI_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${MEDIAWIKI_DB_NAME:=mediawiki}

if [ -z "$MEDIAWIKI_DB_PASSWORD" ]; then
	echo >&2 'error: missing required MEDIAWIKI_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e MEDIAWIKI_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be MEDIAWIKI_DB_USER and MEDIAWIKI_DB_NAME.)'
	exit 1
fi

if ! [ -e index.php -a -e includes/DefaultSettings.php ]; then
	echo >&2 "MediaWiki not found in $(pwd) - copying now..."

	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	tar cf - --one-file-system -C /usr/src/mediawiki . | tar xf -
	echo >&2 "Complete! MediaWiki has been successfully copied to $(pwd)"
fi

#
# Generate symlinks to the following mediawiki data dirs:
#
#		images/
#		extensions/
#
# and symlinks to the following mediawiki data files:
#
#		LocalSettings.php
#		AdminSettings.php
#
: ${MEDIAWIKI_SHARED:=/var/www-shared/html}
if [[ -d "$MEDIAWIKI_SHARED" ]]; then

	for dir in "images" "extensions"; do
		if [[ ! -d "$MEDIAWIKI_SHARED/$dir" ]]; then 
			mv "$dir" "$MEDIAWIKI_SHARED/$dir"
		else
			rm -rf "$dir"
		fi
		echo "Symlinking $dir to $MEDIAWIKI_SHARED/$dir"
		ln -s "$MEDIAWIKI_SHARED/$dir" "$dir"
	done

	for file in "LocalSettings.php" "AdminSettings.php"; do
		[[ ! -e "$MEDIAWIKI_SHARED/$file" ]] && touch "$MEDIAWIKI_SHARED/$file" \
			|| [[ -e "$file" ]] && rm "$file"
		echo "Symlinking $file to $MEDIAWIKI_SHARED/$file"
		ln -s "$MEDIAWIKI_SHARED/$file" "$file"
	done

fi

#
# Create the mediawiki database if it doesn't exist
#
: ${MEDIAWIKI_DB_HOST:=${MYSQL_PORT_3306_TCP#tcp://}}
mysql -u "${MEDIAWIKI_DB_USER}" \
			-h "${MEDIAWIKI_DB_HOST}" \
			--password="${MEDIAWIKI_DB_PASSWORD}" \
			-e "CREATE DATABASE IF NOT EXISTS ${MEDIAWIKI_DB_NAME}"

if [[ -n "${MEDIAWIKI_MYSQL_DUMP}" && -e "${MEDIAWIKI_MYSQL_DUMP}" ]]; then
	echo "Installing mysql dump from $MEDIAWIKI_MYSQL_DUMP"
	mysql -u "${MEDIAWIKI_DB_USER}" \
				-h "${MEDIAWIKI_DB_HOST}" \
				--password="${MEDIAWIKI_DB_PASSWORD}" "${MEDIAWIKI_DB_NAME}" \
				< "${MEDIAWIKI_MYSQL_DUMP}"
fi

#
# Run the maintenance/update.php script if specified
#
if [[ -n "${MEDIAWIKI_UPDATE_DB}" ]]; then
	echo "Upgrading the database schema, this may take a few minutes..."
	php maintenance/update.php
fi 

chown -R www-data: .

export MEDIAWIKI_SITE_NAME MEDIAWIKI_DB_HOST MEDIAWIKI_DB_USER \
			 MEDIAWIKI_DB_PASSWORD MEDIAWIKI_DB_NAME MEDIAWIKI_MYSQL_DUMP

exec "$@"
