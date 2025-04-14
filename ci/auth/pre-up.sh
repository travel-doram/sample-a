#!/bin/bash
# A script to check for KITE_ENV and connect to the right k8s cluster
# Maintainer: Doram Greenblat <doram@ovex.io>
# Rewritten to remove Terraform requirements to be used when possible

INFO="[\033[0;33mINFO\033[0m] "
OK="[\033[0;32mSUCCESS\033[0m] "
ERROR="[\033[0;31mERROR\033[0m] "

[ -z "$ENVPREFIX" ] && echo -e "${ERROR}Usage: ENVPREFIX=*env_prefix* ./ci/script.sh\n" && exit 10
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}")/../" && pwd )"
CONFIGPATH=$WORKDIR/auth

ENVFILE=${CONFIGPATH}/.env.${ENVPREFIX}
set -o allexport
source ${ENVFILE}
set +o allexport

authKubeGcloud () {
    gcloud components install gke-gcloud-auth-plugin
    gcloud auth configure-docker europe-west4-docker.pkg.dev --quiet
    gcloud container clusters get-credentials ${K8S_CLUSTER} \
        --zone ${K8S_ZONE} --project ${K8S_PROJECT}
    return $?
}

googleAuthentication () {
    if [ -z "$CI" ];
    then
        gcloud config set project ${K8S_PROJECT}
    else
        googleAuthenticationGithub
    fi
    return $?
}

googleAuthenticationGithub () {
    # Github does all the dirty work for us
    return 0
}

googleAuthenticationBitBucket () {
    # Set variables
    GOOGLE_CREDENTIALS='gcp_temp_cred.json'
    export DOCKER_BUILDKIT=1
    # OVX-558 :: Force bitbucket Runner Docker Binaries to avoid buildx in GCP container
    export PATH=/usr/bin:$PATH          
    # Configure Workload Identity Federation via a credentials file.
    echo ${BITBUCKET_STEP_OIDC_TOKEN} > .ci_job_jwt_file
    gcloud iam workload-identity-pools create-cred-config "${WIF_PROVIDER}" \
        --service-account="${SERVICE_ACCOUNT}" \
        --output-file="${GOOGLE_CREDENTIALS}" \
        --credential-source-file=.ci_job_jwt_file
    gcloud config set project $K8S_PROJECT
    gcloud config set auth/credential_file_override "${GOOGLE_CREDENTIALS}"
    gcloud auth login --cred-file=${GOOGLE_CREDENTIALS}
    # Now you can run gcloud commands authenticated as the impersonated service account.
    gcloud auth configure-docker europe-west4-docker.pkg.dev
    gcloud auth configure-docker gcr.io
    return $?
}

if [ -z $DOCKER_AUTHENTICATED ];
then
    DOCKER_AUTHENTICATED=0;
else
    if [ $DOCKER_AUTHENTICATED -eq 1 ];
    then
        echo -e "${INFO}Authentication Bypassed. Already Authenticated\n"
        exit 0
    fi
fi

# Check helm version
echo -e "[INFO] Checking helm version\n"
if ! [[ $(helm version --client --short) =~ ^v3\. ]];
then 
    echo -e "${ERROR} Helm version is not in 3.x range. Exiting\n"
    exit 1
fi

if googleAuthentication -eq 0 ;
then
    if authKubeGcloud -eq 0 ;
    then 
        echo -e "${OK} Gcloud Kubernetes authenticated successfully\n"
        export DOCKER_AUTHENTICATED=1
    else 
        echo -e "{$ERROR} Gcloud Kubernetes authentication failed\n"
        exit 1
    fi
else
    echo -e "${ERROR}Gcloud authentication via WiF Failed\n"
    exit 1
fi    

