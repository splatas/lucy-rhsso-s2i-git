#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2020
#
# Created-------: 20200324
# ============================================================
# Description--: Download ImageStream RH-SSO 7.4
#               https://access.redhat.com/containers/?tab=overview#/registry.access.redhat.com/redhat-sso-7/sso74-openshift
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

# Step 4: Validate login in OCP and PROJECT_TARGET exists
check_login_namespace ${PROJECT_TARGET}

# Step 5: Get Properties files
TEMPLATES_DIR=${V_ADMIN_DIR}/../templates
PARAMS_DIR=${TEMPLATES_DIR}/params
check_sso_install_props ${PARAMS_DIR}/${ENV_NAME}/sso_install.properties
#
ENV_PROPS_PATH=${PARAMS_DIR}/${ENV_NAME}/sso_install.properties
TEMPLATE_PATH=${TEMPLATES_DIR}/rhsso/${TEMPLATE_FILE_NAME}

# Step 6: Replace template in project
oc replace -f ${TEMPLATE_PATH} -n ${PROJECT_TARGET} --force

# Step 7: Get templates
#oc get templates -n ${PROJECT_TARGET} | grep sso7
msg "Creating Application..."
#
# Step 8: Process Template using the properties files:
msg "oc process ${TEMPLATE_NAME} --param-file=${ENV_PROPS_PATH} -n ${PROJECT_TARGET}"
oc process ${TEMPLATE_NAME} --param-file=${ENV_PROPS_PATH} | oc apply -f - -n ${PROJECT_TARGET}

exit 0

#
# EOF