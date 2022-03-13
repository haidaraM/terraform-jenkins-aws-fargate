#!/bin/bash

set -e
JENKINS_CONF_LOCAL_PATH="${JENKINS_HOME}/jenkins.yaml"

if [[ -n "${JENKINS_CONF_S3_URL}"  ]]; then
  echo "Getting Jenkins configuration from ${JENKINS_CONF_S3_URL} for JCAS plugin"
  # this file will be read by jenkins configuration as code plugin at EVERY START UP of the Controller
  aws s3 cp "${JENKINS_CONF_S3_URL}" "${JENKINS_CONF_LOCAL_PATH}"
else
  # see https://github.com/jenkinsci/configuration-as-code-plugin/issues/825
  echo "Removing ${JENKINS_CONF_LOCAL_PATH} to avoid override existing configuration"
  rm -f "${JENKINS_CONF_LOCAL_PATH}"
fi

# entrypoint from the docker image
exec tini -- /usr/local/bin/jenkins.sh
