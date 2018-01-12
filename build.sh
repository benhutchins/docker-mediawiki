#!/bin/bash
echo "This script builds distribution versions for several mediawiki versions"

REPO="benhutchins/mediawiki"
VERSIONS=(1.30.0 1.29.2 1.27.4 1.25.2 1.24.3 1.23.10)
LATEST='1.23'
LTS='1.27'

echo "Building base image"
docker build -f Dockerfile-base -t benhutchins/mediawiki:base .
# we don't push the base image, it's just a local thing, but speeds up
# builds of each version since it provides standard base that doesn't get
# rebuild and doesn't get a broken cache as easily

for version in ${VERSIONS[@]}; do
  echo "Building $REPO:$version"
  docker build \
    --build-arg MEDIAWIKI_VERSION=$version \
    -f Dockerfile \
    -t $REPO:$version \
    .

  versionWithoutPatch="${version%.*}"

  echo "Tagging as $REPO:$versionWithoutPatch"
  docker tag $REPO:$version $REPO:$versionWithoutPatch
done

echo "Tagigng Latest"
docker tag $REPO:$LATEST $REPO:latest

echo "Tagging LTS"
docker tag $REPO:$LTS $REPO:lts

read -p "Press enter to push build images to Docker Hub"

echo "Pushing images to Docker Hub"
for version in ${VERSIONS[@]}; do
  echo "Pushing $REPO:$version to Docker Hub"
  docker push $REPO:$version

  versionWithoutPatch="${version%.*}"
  echo "Pushing $REPO:$versionWithoutPatch to Docker Hub"
  docker push $REPO:$versionWithoutPatch
done

echo "Pushing Latest to Docker Hub"
docker push $REPO:latest

echo "Pushing LTS to Docker Hub"
docker push $REPO:lts
