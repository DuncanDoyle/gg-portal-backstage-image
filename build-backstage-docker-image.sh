#!/bin/sh

# Check that a Docker tag has been passed.
if [ -z "$1" ]
then
   echo "Please pass a tag that will be used for the Backstage Docker image as an argument to this script."
   exit 1
fi

DOCKER_IMAGE_TAG=$1

pushd backstage

echo "Generate the Docker image.\n"
#yarn build-image --tag backstage:$DOCKER_IMAGE_TAG
# Not using yarn build-image, as we want to do a multi-arch build.

docker buildx build -f packages/backend/Dockerfile --platform linux/amd64,linux/arm64 --no-cache --push -t duncandoyle/backstage-gloo -t duncandoyle/backstage-gloo:$DOCKER_IMAGE_TAG .

echo "Backstage Docker image created successfully with name 'backstage-gloo' and tag '$DOCKER_IMAGE_TAG'.\n"

popd