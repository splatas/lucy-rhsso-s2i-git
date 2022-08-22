#!/bin/bash

injected_dir=$1

echo "[S2I install.sh] injected_dir: ${injected_dir}"
echo "[S2I install.sh] ENV_FILES---: ${ENV_FILES}"
source /usr/local/s2i/install-common.sh
#######################
cp ${injected_dir}/configuration/* ${JBOSS_HOME}/standalone/configuration/

####################
# Add Oracle JDBC Driver Module & Driver
install_modules ${injected_dir}/modules
#
configure_drivers ${injected_dir}/configuration/oracle_driver.properties
#######################
#######################

echo "[S2I install.sh] End"

#
# EOF
