bold=$(tput bold)
normal=$(tput sgr0)

echo "${bold}Removing old images${normal}"
docker rmi benhutchins/mediawiki:1.25
docker rmi benhutchins/mediawiki:1.24
docker rmi benhutchins/mediawiki:1.23
docker rmi benhutchins/mediawiki:postgres
docker rmi benhutchins/mediawiki:latest

echo "${bold}Building with MediaWiki 1.25${normal}"
docker build -t benhutchins/mediawiki:1.25 -f Dockerfile-1.25 .

echo "${bold}Building with MediaWiki 1.24${normal}"
docker build -t benhutchins/mediawiki:1.24 -f Dockerfile-1.24 .

echo "${bold}Building with MediaWiki 1.23${normal}"
docker build -t benhutchins/mediawiki:1.23 -f Dockerfile-1.23 .

echo "${bold}Building with MediaWiki 1.25, using Postgres${normal}"
docker build -t benhutchins/mediawiki:postgres -f Dockerfile-postgres .

echo "${bold}Creating :latest tag${normal}"
docker tag benhutchins/mediawiki:1.25 benhutchins/mediawiki:latest
