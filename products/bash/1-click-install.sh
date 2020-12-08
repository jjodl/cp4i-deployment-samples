#!/bin/bash
#******************************************************************************
# Licensed Materials - Property of IBM
# (c) Copyright IBM Corporation 2019. All Rights Reserved.
#
# Note to U.S. Government Users Restricted Rights:
# Use, duplication or disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#******************************************************************************

#******************************************************************************
# PREREQUISITES:
#   - Logged into cluster on the OC CLI (https://docs.openshift.com/container-platform/4.4/cli_reference/openshift_cli/getting-started-cli.html)
#   - If running without parameters, all parameters must be set as environment variables
#
# PARAMETERS:
#   -a : <eventEnabledInsuranceDemo> (string), If event enabled insurance demo is to be setup. Defaults to "false"
#   -b : <demoDeploymentBranch> (string), The demo deployment branch to be used, Defaults to 'main'
#   -d : <demoPreparation> (string), If all demos are to be setup. Defaults to "false"
#   -e : <demoAPICEmailAddress> (string), The email address APIC uses to notify of portal configuration. Defaults to "your@email.address"
#   -f : <drivewayDentDeletionDemo> (string),  If driveway dent deletion demo is to be setup. Defaults to "false"
#   -h : <demoAPICMailServerHost> (string), Host name of the mail server. Defaults to "smtp.mailtrap.io"
#   -j : <tempERKey> (string), IAM API key for accessing the entitled registry.
#   -k : <tempRepo> (string), For accessing different Registry
#   -l : <DOCKER_REGISTRY_USER> (string), Docker registry username
#   -m : <demoAPICMailServerUsername> (string), Username for the mail server. Defaults to "<your-username>"
#   -n : <JOB_NAMESPACE> (string), Namespace for the 1-click install
#   -o : <demoAPICMailServerPort> (string), Port number of the mail server. Defaults to "2525"
#   -p : <csDefaultAdminPassword> (string), Common service default admin password
#   -q : <demoAPICMailServerPassword> (string), Password for the mail server.
#   -r : <navReplicaCount> (string), Platform navigator replicas, Defaults to 3
#   -s : <DOCKER_REGISTRY_PASS> (string), Docker registry password
#   -t : <ENVIRONMENT> (string), Environment for installation, 'staging' when you want to use the staging entitled registry
#   -u : <csDefaultAdminUser> (string), Default common service username. Defaults to "admin"
#   -v : <useFastStorageClass> (string), If using fast storage class for installation. Defaults to 'false'
#   -w : <testDrivewayDentDeletionDemoE2E> (string), If testing the Driveway dent deletion demo E2E. Defaults to 'false'
#
# USAGE:
#   With defaults values
#     ./1-click-install.sh
#
#   Overriding the params
#     ./1-click-install.sh -a <eventEnabledInsuranceDemo> -b <demoDeploymentBranch> -d <demoPreparation> -e <demoAPICEmailAddress> -f <drivewayDentDeletionDemo> -h <demoAPICMailServerHost> -j <tempERKey> -k <tempRepo> -l <DOCKER_REGISTRY_USER> -m <demoAPICMailServerUsername> -n <JOB_NAMESPACE> -o <demoAPICMailServerPort> -p <csDefaultAdminPassword> -q <demoAPICMailServerPassword> -r <navReplicaCount> -s <DOCKER_REGISTRY_PASS> -t <ENVIRONMENT> -u <csDefaultAdminUser> -v <useFastStorageClass>

function divider() {
  echo -e "\n-------------------------------------------------------------------------------------------------------------------\n"
}

function usage() {
  echo "Usage: $0 -a <eventEnabledInsuranceDemo> -b <demoDeploymentBranch> -d <demoPreparation> -e <demoAPICEmailAddress> -f <drivewayDentDeletionDemo> -h <demoAPICMailServerHost> -j <tempERKey> -k <tempRepo> -l <DOCKER_REGISTRY_USER> -m <demoAPICMailServerUsername> -n <JOB_NAMESPACE> -o <demoAPICMailServerPort> -p <csDefaultAdminPassword> -q <demoAPICMailServerPassword> -r <navReplicaCount> -s <DOCKER_REGISTRY_PASS> -t <ENVIRONMENT> -u <csDefaultAdminUser> -v <useFastStorageClass>"
  divider
  exit 1
}

TICK="\xE2\x9C\x85"
CROSS="\xE2\x9D\x8C"
ALL_DONE="\xF0\x9F\x92\xAF"
INFO="\xE2\x84\xB9"
CURRENT_DIR=$(dirname $0)
MISSING_PARAMS="false"
IMAGE_REPO="cp.icr.io"
PASSWORD_CHANGE="true"
DEFAULT_BLOCK_STORAGE=""
DEFAULT_FILE_STORAGE="ibmc-file-gold-gid"
cognitiveCarRepairDemo=false
mappingAssistDemo=false
weatherChatbotDemo=false

while getopts "a:b:d:e:f:h:j:k:l:m:n:o:p:q:r:s:t:u:v:w:" opt; do
  case ${opt} in
  a)
    eventEnabledInsuranceDemo="$OPTARG"
    ;;
  b)
    demoDeploymentBranch="$OPTARG"
    ;;
  d)
    demoPreparation="$OPTARG"
    ;;
  e)
    demoAPICEmailAddress="$OPTARG"
    ;;
  f)
    drivewayDentDeletionDemo="$OPTARG"
    ;;
  h)
    demoAPICMailServerHost="$OPTARG"
    ;;
  j)
    tempERKey="$OPTARG"
    ;;
  k)
    tempRepo="$OPTARG"
    ;;
  l)
    DOCKER_REGISTRY_USER="$OPTARG"
    ;;
  m)
    demoAPICMailServerUsername="$OPTARG"
    ;;
  n)
    JOB_NAMESPACE="$OPTARG"
    ;;
  o)
    demoAPICMailServerPort="$OPTARG"
    ;;
  p)
    csDefaultAdminPassword="$OPTARG"
    ;;
  q)
    demoAPICMailServerPassword="$OPTARG"
    ;;
  r)
    navReplicaCount="$OPTARG"
    ;;
  s)
    DOCKER_REGISTRY_PASS="$OPTARG"
    ;;
  t)
    ENVIRONMENT="$OPTARG"
    ;;
  u)
    csDefaultAdminUser="$OPTARG"
    ;;
  v)
    useFastStorageClass="$OPTARG"
    ;;
  w)
    testDrivewayDentDeletionDemoE2E="$OPTARG"
    ;;
  \?)
    usage
    ;;
  esac
done

if [[ -z "${JOB_NAMESPACE// /}" ]]; then
  echo -e "$CROSS [ERROR] 1-click install namespace is empty. Please provide a value for '-n' parameter."
  MISSING_PARAMS="true"
fi

if [[ -z "${navReplicaCount// /}" ]]; then
  echo -e "$CROSS [ERROR] 1-click install platform navigator replica count is empty. Please provide a value for '-r' parameter."
  MISSING_PARAMS="true"
fi

if [[ -z "${csDefaultAdminUser// /}" ]]; then
  echo -e "$CROSS [ERROR] 1-click install default admin username is empty. Please provide a value for '-u' parameter."
  MISSING_PARAMS="true"
fi

if [[ -z "${demoPreparation// /}" ]]; then
  echo -e "$CROSS [ERROR] 1-click install demo preparation parameter is empty. Please provide a value for '-d' parameter."
  MISSING_PARAMS="true"
fi

if [[ -z "${csDefaultAdminPassword// /}" ]]; then
  echo -e "$CROSS [ERROR] 1-click install default admin password is empty. Please provide a value for '-p' parameter."
  MISSING_PARAMS="true"
fi

if [[ -z "${ENVIRONMENT// /}" ]]; then
  echo -e "$CROSS [ERROR] 1-click install environment is empty. Please provide a value for '-t' parameter."
  MISSING_PARAMS="true"
fi

if [[ -z "${demoDeploymentBranch// /}" ]]; then
  echo -e "$INFO [INFO] 1-click install demo deployment branch is empty. Setting the default value of 'main' for it."
  demoDeploymentBranch="main"
fi

if [[ -z "${eventEnabledInsuranceDemo// /}" ]]; then
  echo -e "$INFO [INFO] 1-click install event enabled insurance parameter is empty. Setting the default value of 'false' for it."
  eventEnabledInsuranceDemo="false"
fi

if [[ -z "${drivewayDentDeletionDemo// /}" ]]; then
  echo -e "$INFO [INFO] 1-click install driveway dent deletion parameter is empty. Setting the default value of 'false' for it."
  drivewayDentDeletionDemo="false"
fi

if [[ -z "${useFastStorageClass// /}" ]]; then
  echo -e "$INFO [INFO] 1-click install fast storage class flag is empty. Setting the default value of 'false' for it."
  useFastStorageClass="false"
fi

if [[ -z "${testDrivewayDentDeletionDemoE2E// /}" ]]; then
  echo -e "$INFO [INFO] 1-click install test driveway dent deletion demo parameter is empty. Setting the default value of 'false' for it."
  testDrivewayDentDeletionDemoE2E="false"
fi

if [[ "$MISSING_PARAMS" == "true" ]]; then
  divider
  exit 1
fi

if [[ "$demoPreparation" == "true" ]]; then
  cognitiveCarRepairDemo=true
  drivewayDentDeletionDemo=true
  eventEnabledInsuranceDemo=true
  mappingAssistDemo=true
  weatherChatbotDemo=true
fi

if [[ "$drivewayDentDeletionDemo" == "true" ]]; then
  drivewayDentDeletionDemo=true
fi

if [[ "$eventEnabledInsuranceDemo" == "true" ]]; then
  eventEnabledInsuranceDemo=true
fi

echo -e "$INFO [INFO] Current directory for 1-click install: '$CURRENT_DIR'"
echo -e "$INFO [INFO] 1-click namespace: '$JOB_NAMESPACE'"
echo -e "$INFO [INFO] Navigator replica count: '$navReplicaCount'"
echo -e "$INFO [INFO] Demo deployment branch: '$demoDeploymentBranch'"
echo -e "$INFO [INFO] Default common service username: '$csDefaultAdminUser'"
echo -e "$INFO [INFO] Setup all demos: '$demoPreparation'"
echo -e "$INFO [INFO] Setup event enabled insurance demo: '$eventEnabledInsuranceDemo'"
echo -e "$INFO [INFO] Setup driveway dent deletion demo: '$drivewayDentDeletionDemo'"
echo -e "$INFO [INFO] Setup cognitive car repair demo: '$cognitiveCarRepairDemo'"
echo -e "$INFO [INFO] Setup mapping assist demo: '$mappingAssistDemo'"
echo -e "$INFO [INFO] Setup weather chatbot demo: '$weatherChatbotDemo'"
echo -e "$INFO [INFO] APIC email address: '$demoAPICEmailAddress'"
echo -e "$INFO [INFO] APIC mail server hostname: '$demoAPICMailServerHost'"
echo -e "$INFO [INFO] APIC mail server port: '$demoAPICMailServerPort'"
echo -e "$INFO [INFO] APIC mail server username: '$demoAPICMailServerUsername'"
echo -e "$INFO [INFO] Image repository for downloading images: '$IMAGE_REPO'"
echo -e "$INFO [INFO] Temporary ER repository: '$tempRepo'"
echo -e "$INFO [INFO] Docker registry username: '$DOCKER_REGISTRY_USER'"
echo -e "$INFO [INFO] Environment for installation: '$ENVIRONMENT'"
echo -e "$INFO [INFO] If using fast storage for the installation: '$useFastStorageClass'"
echo -e "$INFO [INFO] If testing the driveway dent deletion demo E2E: '$testDrivewayDentDeletionDemoE2E'"

divider

echo -e "$INFO [INFO] Doing a validation check before installation..."
if ! $CURRENT_DIR/1-click-pre-validation.sh -n "$JOB_NAMESPACE" -p "$csDefaultAdminPassword" -r "$navReplicaCount" -u "$csDefaultAdminUser" -d "$demoPreparation"; then
  echo -e "$CROSS [ERROR] 1-click pre validation failed"
  divider
  exit 1
fi

divider

if [[ -z "${tempERKey}" ]]; then
  # Use the entitlement key
  export DOCKER_REGISTRY_USER=${DOCKER_REGISTRY_USER:-ekey}
  export DOCKER_REGISTRY_PASS=${DOCKER_REGISTRY_PASS:-none}
else
  # Use the tempERKey override as an api key
  export DOCKER_REGISTRY_USER="iamapikey"
  export DOCKER_REGISTRY_PASS=${tempERKey}
fi

if [[ "$ENVIRONMENT" == "STAGING" ]]; then
  export IMAGE_REPO="cp.stg.icr.io"
fi

export IMAGE_REPO=${tempRepo:-$IMAGE_REPO}

if oc get namespace $JOB_NAMESPACE >/dev/null 2>&1; then
  echo -e "$INFO [INFO] namespace $JOB_NAMESPACE already exists"
  divider
else
  echo -e "$INFO [INFO] Creating the '$JOB_NAMESPACE' namespace"
  if ! oc create namespace $JOB_NAMESPACE; then
    echo -e "$CROSS [ERROR] Failed to create the '$JOB_NAMESPACE' namespace"
    divider
    exit 1
  else
    echo -e "$TICK [SUCCESS] Succesfully created the '$JOB_NAMESPACE' namespace"
  fi
fi

divider

# This storage class improves the pvc performance for small PVCs
echo -e "$INFO [INFO] Creating new cp4i-block-performance storage class"
cat <<EOF | oc apply -n $JOB_NAMESPACE -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: cp4i-block-performance
  labels:
    kubernetes.io/cluster-service: "true"
provisioner: ibm.io/ibmc-block
parameters:
  billingType: "hourly"
  classVersion: "2"
  sizeIOPSRange: |-
    "[1-39]Gi:[1000]"
    "[40-79]Gi:[2000]"
    "[80-99]Gi:[4000]"
    "[100-499]Gi:[5000-6000]"
    "[500-999]Gi:[5000-10000]"
    "[1000-1999]Gi:[10000-20000]"
    "[2000-2999]Gi:[20000-40000]"
    "[3000-12000]Gi:[24000-48000]"
  type: "Performance"
reclaimPolicy: Delete
volumeBindingMode: Immediate
EOF

defaultStorageClass=$(oc get sc -o json | jq -r '.items[].metadata | select(.annotations["storageclass.kubernetes.io/is-default-class"] == "true") | .name')

DEFAULT_BLOCK_STORAGE=$defaultStorageClass

if [[ "${useFastStorageClass}" == "true" ]]; then
  echo -e "$INFO [INFO] Current default storage class is: $defaultStorageClass"

  echo -e "$INFO [INFO] Making $defaultStorageClass non-default"
  oc patch storageclass $defaultStorageClass -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

  echo -e "$INFO [INFO] Making cp4i-block-performance default"
  oc patch storageclass cp4i-block-performance -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

  DEFAULT_BLOCK_STORAGE="cp4i-block-performance"
fi

divider

echo -e "$INFO [INFO] Current storage classes:"
oc get sc

divider

# Create secret to pull images from the ER
echo -e "$INFO [INFO] Creating secret to pull images from the ER"
oc -n ${JOB_NAMESPACE} create secret docker-registry ibm-entitlement-key \
  --docker-server=${IMAGE_REPO} \
  --docker-username=${DOCKER_REGISTRY_USER} \
  --docker-password=${DOCKER_REGISTRY_PASS} \
  --dry-run -o yaml | oc apply -f -

divider

echo -e "$INFO [INFO] Checking for the platform-auth-idp-credentials secret"
if oc get secrets platform-auth-idp-credentials -n ibm-common-services; then
  PASSWORD_CHANGE=false
  echo -e "$INFO [INFO] Secret platform-auth-idp-credentials already exist so not updating password and username in the installation with provided values"
else
  echo -e "$INFO [INFO] Secret platform-auth-idp-credentials does exist so will update password and username in the installation with provided values"
fi

divider

echo -e "$INFO [INFO] Applying catalogsources"
cat <<EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: openshift-marketplace
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: docker.io/ibmcom/ibm-common-service-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m

---

apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: ibm-operator-catalog
  publisher: IBM Content
  sourceType: grpc
  image: docker.io/ibmcom/ibm-operator-catalog
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

divider

if ! $CURRENT_DIR/deploy-og-sub.sh -n ${JOB_NAMESPACE}; then
  echo -e "$CROSS [ERROR] Failed to deploy the operator group and subscriptions"
  divider
  exit 1
else
  echo -e "$TICK [SUCCESS] Deployed the operator groups and subscriptions"
fi

divider

if ! $CURRENT_DIR/release-navigator.sh -n ${JOB_NAMESPACE} -r ${navReplicaCount}; then
  echo -e "$CROSS [ERROR] Failed to release navigator"
  divider
  exit 1
else
  echo -e "$TICK [SUCCESS] Successfully released the platform navigator"
fi

divider

# Only update common services username and password if common services is not already installed
if [ "${PASSWORD_CHANGE}" == "true" ]; then
  if ! $CURRENT_DIR/change-cs-credentials.sh -u ${csDefaultAdminUser} -p ${csDefaultAdminPassword}; then
    echo -e "$CROSS [ERROR] Failed to update the common services admin username/password"
    divider
    exit 1
  else
    echo -e "$TICK [SUCCESS] Successfully updated the common services admin username/password"
  fi
else
  echo -e "$INFO [INFO] Retrieve the common service username using the command 'oc get secrets -n ibm-common-services platform-auth-idp-credentials -o jsonpath='{.data.admin_username}' | base64 --decode' "
  echo -e "$INFO [INFO] Retrieve the common service password using the command 'oc get secrets -n ibm-common-services platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 --decode' "
fi

divider

echo -e "$INFO [INFO] Replacing all variables with their values in the demo json file to use as input for the demo script..."
CURRENT_DIR_WITHOUT_DOT_SLASH=${CURRENT_DIR//.\//}

# copy contents of the demos.json into a backup json file
cp $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json $CURRENT_DIR_WITHOUT_DOT_SLASH/demos-backup.json

sed -i -e "s/JOB_NAMESPACE/$JOB_NAMESPACE/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/DEFAULT_BLOCK_STORAGE/$DEFAULT_BLOCK_STORAGE/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/DEFAULT_FILE_STORAGE/$DEFAULT_FILE_STORAGE/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/DEMO_DEPLOYMENT_BRANCH/$demoDeploymentBranch/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/PORG_ADMIN_EMAIL/$demoAPICEmailAddress/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/MAIL_SERVER_HOST/$demoAPICMailServerHost/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/MAIL_SERVER_PORT/$demoAPICMailServerPort/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/MAIL_SERVER_USERNAME/$demoAPICMailServerUsername/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/MAIL_SERVER_PASSWORD/$demoAPICMailServerPassword/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/DEMO_PREPARATION/$demoPreparation/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/COGNITIVE_CAR_REPAIR_DEMO/$cognitiveCarRepairDemo/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/DRIVEWAY_DENT_DELETION_DEMO/$drivewayDentDeletionDemo/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/EVENT_ENABLED_INSURANCE_DEMO/$eventEnabledInsuranceDemo/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/MAPPING_ASSIST_DEMO/$mappingAssistDemo/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
sed -i -e "s/WEATHER_CHATBOT_DEMO/$weatherChatbotDemo/g" $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json

divider && echo -e "$INFO [INFO] Setting up all the selected demos..."
if $CURRENT_DIR/setup-demos.sh -i $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json -o $CURRENT_DIR_WITHOUT_DOT_SLASH/demos-output.json; then
  echo -e "\n$TICK [SUCCESS] Successfully setup all required addons, products and demos in the '$JOB_NAMESPACE' namespace"
else
  echo -e "\n$CROSS [ERROR] Failed to setup all required addons, products and demos in the '$JOB_NAMESPACE' namespace"
  divider
  exit 1
fi

# restore content of demo json file and delete temporary files
cp $CURRENT_DIR_WITHOUT_DOT_SLASH/demos-backup.json $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json
rm -rf $CURRENT_DIR_WITHOUT_DOT_SLASH/demos.json-e $CURRENT_DIR_WITHOUT_DOT_SLASH/demos-backup.json

divider

if [[ ("${demoPreparation}" == "true" || "${drivewayDentDeletionDemo}" == "true") && ("${testDrivewayDentDeletionDemoE2E}" == "true") ]]; then
  if ! $CURRENT_DIR/../../DrivewayDentDeletion/Operators/test-ddd.sh -n ${JOB_NAMESPACE} -b $demoDeploymentBranch; then
    echo -e "$CROSS [ERROR] Failed to run automated test for driveway dent deletion demo"
    divider
    exit 1
  else
    echo -e "$TICK [SUCCESS] Successfully ran the automated test for driveway dent deletion demo"
  fi
fi

divider
