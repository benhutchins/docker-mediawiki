bold=$(tput bold)
normal=$(tput sgr0)

echo "${bold}Building with MediaWiki 1.25${normal}"
docker build -t benhutchins/mediawiki:1.25 -f Dockerfile .

echo "${bold}Building with MediaWiki 1.24${normal}"
docker build -t benhutchins/mediawiki:1.24 -f Dockerfile-1.24 .

echo "${bold}Building with MediaWiki 1.23${normal}"
docker build -t benhutchins/mediawiki:1.23 -f Dockerfile-1.23 .

echo "${bold}Building with MediaWiki 1.25, using Postgres${normal}"
docker build -t benhutchins/mediawiki:postgres -f Dockerfile-postgres .

echo "${bold}Creating :latest tag${normal}"
docker tag benhutchins/mediawiki:1.25 benhutchins/mediawiki:latest
