#!/bin/bash

if ! [ -e index.php -a -e includes/DefaultSettings.php ]; then
	echo >&2 "MediaWiki not found in $(pwd) - copying now..."

	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	rsync --archive --one-file-system --quiet /usr/src/mediawiki/ ./
	echo >&2 "Complete! MediaWiki has been successfully copied to $(pwd)"
	if [ ! -e .htaccess ]; then
		cat > .htaccess <<-'EOF'
			RewriteEngine On
			RewriteBase /
			RewriteRule ^index\.php$ - [L]
			RewriteCond %{REQUEST_FILENAME} !-f
			RewriteCond %{REQUEST_FILENAME} !-d
			RewriteRule . /index.php [L]
		EOF
	fi
fi

exec "$@"
