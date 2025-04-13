#!/bin/bash
# This should speed up deployment times.
# Build occurs at pull requests and merge.
#   - if container exists on GCR, skip build/push and just deploy.

PATH=/usr/bin:$PATH
DOCKER_BUILDKIT=1
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
CONFIGPATH=$WORKDIR/ci
if [ -z "$CI" ]; then
    BUILDARGS="--platform linux/amd64"
fi

# Authenticate and set env
source ${CONFIGPATH}/auth/pre-up.sh

function manifestInspect() {
    # Check if image and tag exists on registry and do not run build step if image/tag exists as this is a waste of everyones time
    if docker manifest inspect $1 >/dev/null; then
        # Pass success to calling party
        echo "1"
    else
        # Pass failure to calling party
        echo "0"
    fi
}

# BUILD IMAGE
image_name=europe-west4-docker.pkg.dev/ts-infra-demo/private/sample-a

docker build ${BUILDARGS} -t ${image_name}:${BITBUCKET_COMMIT} .
docker push ${image_name}:${BITBUCKET_COMMIT}
if [ -z "${BITBUCKET_TAG}" ]; then
    echo -e "${INFO} Not a deployment, nothing more to do here"
else
    docker tag ${image_name}:${BITBUCKET_COMMIT} ${image_name}:${BITBUCKET_TAG}
    docker push ${image_name}:${BITBUCKET_TAG}
fi
