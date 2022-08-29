#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2022
#
# Created-------: 202208
# ============================================================
# Description--: Download ImageStream RH-SSO 7.6
#                https://catalog.redhat.com/software/containers/rh-sso-7/sso76-openshift-rhel8/629651e2cddbbde600c0a2ec
#                registry.redhat.io/rh-sso-7/sso76-openshift-rhel8
#
# ============================================================
#
# ============================================================
# Pre Steps---:
# chmod 774 *.sh
# ============================================================
#
#
#
# EOH

# Step 1: Set current DIR and default variables:
V_ADMIN_DIR=$(dirname $0)
source ${V_ADMIN_DIR}/environment.sh
source ${V_ADMIN_DIR}/functions.sh

# Step 2: Parser Input Parameters
while [ $# -gt 0 ]
do
    case $1 in
      -n | --namespace )  shift
                          PROJECT_TARGET="$1"
                          ENV_NAME="$1"
                          ;;
       * )                usage_info
                          exit 1
    esac
    shift
done

# Step 3: Set the PROJECT_TARGET
if [ -z ${PROJECT_TARGET} ];then
  # Default: minishift
  ENV_NAME=minishift
  PROJECT_TARGET=myproject
  msg "We are using a minishift environment!!"
fi


function checkImportImage(){
  # Step: Check ImageStream Version:
  msg "Executing: oc get istag/${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} -o name --no-headers -n ${IMAGE_STREAM_NAMESPACE}"
  istag_name_version_new=$(oc get istag/${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} -o name --no-headers -n ${IMAGE_STREAM_NAMESPACE} 2>/dev/null)
  msg "ISTAG: '${istag_name_version_new}' from '${IMAGE_STREAM_NAMESPACE}' namespace"
  if [ -z "${istag_name_version_new}" ]; then
      msg "Executing: oc import-image rh-sso-7/${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} --from=registry.redhat.io/rh-sso-7/${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} --confirm -n ${IMAGE_STREAM_NAMESPACE}"
      oc import-image rh-sso-7/${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} --from=registry.redhat.io/rh-sso-7/${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} --confirm -n ${IMAGE_STREAM_NAMESPACE}
      if [ $? -ne 0 ]; then
        err "Error in the Import Image process. See the oc import-image sentence."
        exit 1
      fi
      msg "The ${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} imagestream imported."
  else
    msg "The ${IMAGE_STREAM_NAME}:${IMAGE_STREAM_TAG} exists in ${IMAGE_STREAM_NAMESPACE}"
  fi
}

# Step 4: Validate login in OCP and PROJECT_TARGET exists
check_login_namespace ${PROJECT_TARGET}
#
PARAMS_DIR=${V_ADMIN_DIR}/../templates/params
check_sso_install_props ${PARAMS_DIR}/${ENV_NAME}/sso_install.properties
#
source ${PARAMS_DIR}/${ENV_NAME}/sso_install.properties
if [ -f ${PARAMS_DIR}/${ENV_NAME}/.credentials ]; then
  source ${PARAMS_DIR}/${ENV_NAME}/.credentials
fi

declare -a secretnames=("${GIT_SECRET}" "${MAVEN_CREDENTIALS_SECRET}" )

# Create Secrets for minishift
git_secret=""
git_secret=$(oc get secret ${GIT_SECRET} -o name --no-headers -n ${PROJECT_TARGET} 2>/dev/null)
if [ -z "${git_secret}" ]; then
  oc create secret generic ${GIT_SECRET}                   --from-literal="username=${GIT_CRED_USERNAME}"       --from-literal="password=${GIT_CRED_PWD}"        --type=kubernetes.io/basic-auth -n ${PROJECT_TARGET}
fi
maven_secret=""
maven_secret=$(oc get secret ${MAVEN_CREDENTIALS_SECRET} -o name --no-headers -n ${PROJECT_TARGET} 2>/dev/null)
if [ -z "${maven_secret}" ]; then
  oc create secret generic ${MAVEN_CREDENTIALS_SECRET}     --from-literal="username=${MAVEN_REPO_USERNAME}"     --from-literal="password=${MAVEN_REPO_PASSWORD}" --type=kubernetes.io/basic-auth -n ${PROJECT_TARGET}
fi

#
for secretname in ${secretnames[@]}; do
  msg "Add labels to ${secretname} secret"
  #oc label secret ${secretname}  app=${APPLICATION_NAME}         --overwrite=true -n ${PROJECT_TARGET}
  #oc label secret ${secretname}  application=${APPLICATION_NAME} --overwrite=true -n ${PROJECT_TARGET}
done
#
webhooks=${!WEBHOOK_SECRET_*}
msg "WEBHOOKS: ${webhooks}"
j=0
for webhook in ${webhooks}; do
  whsuffix=$(printf "%02d\n" ${j})
  msg "${webhook} ${!webhook} ${whsuffix}"
  #oc create secret generic ${!webhook} --from-literal=WebHookSecretKey=ssowebhook${whsuffix} -n ${PROJECT_TARGET}
  #oc label secret ${!webhook}  app=${APPLICATION_NAME}         --overwrite=true -n ${PROJECT_TARGET}
  #oc label secret ${!webhook}  application=${APPLICATION_NAME} --overwrite=true -n ${PROJECT_TARGET}
  let "j+=1"
  unset ${webhook}
done

# Create secret imagestreamsecret
pull_secret=""
pull_secret=$(oc get secret ${BC_PULL_SECRET_NAME} -o name --no-headers -n ${PROJECT_TARGET} 2>/dev/null)
if [ -z "${pull_secret}" ]; then
  oc create secret docker-registry ${BC_PULL_SECRET_NAME}  --docker-username="${REG_REDHAT_IO_USERNAME}" --docker-password="${REG_REDHAT_IO_PWD}"  --docker-server=registry.redhat.io --docker-email="${REG_REDHAT_IO_EMAIL}" -n ${PROJECT_TARGET}
  oc secrets link default ${BC_PULL_SECRET_NAME} --for=pull
  oc secrets link builder ${BC_PULL_SECRET_NAME} --for=pull
else
  msg "The ${BC_PULL_SECRET_NAME} pull secret exists"
fi

# sso74-openshift-rhel8 ===> registry.redhat.io/rh-sso-7/sso74-openshift-rhel8:${IMAGE_STREAM_TAG}
checkImportImage

exit 0
#
# EOF