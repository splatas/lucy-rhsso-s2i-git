#!/bin/bash

injected_dir=$1
caller

echo "[S2I install.sh] injected_dir: ${injected_dir}"
echo "[S2I install.sh] ENV_FILES---: ${ENV_FILES}"

echo "[S2I install.sh] Workaround: /usr/local/s2i/install-common.sh: line 54: getConfigurationMode: command not found"
sed -i "s|source \${JBOSS_HOME}/bin/launch/openshift-common.sh|source \${JBOSS_HOME}/bin/launch/openshift-common.sh\nsource \${JBOSS_HOME}/bin/launch/launch-common.sh\n|g" /usr/local/s2i/install-common.sh

source /usr/local/s2i/install-common.sh
#######################
cp ${injected_dir}/configuration/* ${JBOSS_HOME}/standalone/configuration/

# Workaround Solved:
####################
# Add Oracle JDBC Driver Module & Driver
echo "[S2I install.sh] Before install_modules"
install_modules ${injected_dir}/modules
#
echo "[S2I install.sh] Before configure drivers"
configure_drivers ${injected_dir}/configuration/oracle_driver.properties
#######################
#######################

echo "[S2I install.sh] End"

#
# EOF
