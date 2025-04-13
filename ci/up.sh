#!/bin/bash

WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}")/../" && pwd )"
CIPATH=$WORKDIR/ci

source ${CIPATH}/auth/pre-up.sh

case "$1" in
dry-run)
    HELMCOMMAND="upgrade --dry-run --debug"
    ;;
installdry-run)
    HELMCOMMAND="install --dry-run --debug"
    ;;
template)
    HELMCOMMAND="template --debug"
    ;;
*)
    HELMCOMMAND="upgrade --install --debug"
    ;;
esac

# Default to applogic unless release_name_override set
# This is to allow a second deployment and set of values in same cluster.
# Although will probably never be used
release_name="${RELEASE_NAME_OVERRIDE:-sample-a}"
export release_name=${release_name}
namespace="ts-public"
export namespace=${namespace}


if [ -z "${BITBUCKET_TAG}" ]
then
    image_tag="${BITBUCKET_COMMIT}"
    export image_tag="${BITBUCKET_COMMIT}"
else
    image_tag="${BITBUCKET_TAG}"
    export image_tag="${BITBUCKET_TAG}"
fi

# Create namespace if it doesn't exist
kubectl get namespace | grep -q "${namespace}" || kubectl create namespace ${namespace}
# Label namespace for secret-init mutations
kubectl label namespace ${namespace} kube-secrets-init.doit-intl.com/enable-mutation=true --overwrite=true >/dev/null 2>&1

# Perform bash variable/env substitution in values file
VALUESFILE_SUBSTITUTED="${CIPATH}/sample-a.substituted.yaml"
envsubst < "${CIPATH}/helm/values.yaml" >  ${VALUESFILE_SUBSTITUTED}

# Allow custom annotations defined per environment file.
params=(
    --set image.tag="${image_tag}"
    ${annotations[@]}
)

echo -e "${INFO} Deploying ${release_name}"
echo -e "${INFO} Environment: ${ENVPREFIX}"
echo -e "${INFO} cat of ${CIPATH}/auth/.env.${ENVPREFIX}"

helm ${HELMCOMMAND} ${release_name} ci/helm -f ${VALUESFILE_SUBSTITUTED} -n ${namespace} "${params[@]}"

# Cleanup my playroom
rm -f ${VALUESFILE_SUBSTITUTED}