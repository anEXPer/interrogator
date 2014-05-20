#!/bin/bash

# Exit on error
set -e

# Display Commands/dev-mode
set -x

# Take app name as an argument:
NAME=$1
ORG=$2
SPACE=$3

# Verify the presence of the cli and note the version
cf --version

# Set CF to use a seperate config file 
export CF_HOME=/tmp/interrogator

# Login and target the app's space
cf api api.staging.cf-app.com
cf auth interrogator interrogator
cf target -o $ORG -s $SPACE

# Get the app's name, instances, quota, and routes
# and store them as json
CF_TRACE=true cf app $NAME | grep ',"name":' > /tmp/interrogator/app.json

# Assign them to env vars
INTERROGATOR_APP_NAME="$NAME"
INTERROGATOR_MANIFEST=/tmp/interrogator/$INTERROGATOR_APP_NAME-manifest.yml
# Saved for posterity so you can see how insane this was before going after the JSON:
# INTERROGATOR_INSTANCES=$(grep instances: /tmp/interrogator/interrogator_cf_app_with_trace.txt | awk '{print substr ($0,length,1)}')
# Now the sane way:
INTERROGATOR_INSTANCES=$(jq '.instances' /tmp/interrogator/app.json)
INTERROGATOR_MEMORY=$(jq '.memory' /tmp/interrogator/app.json)

# Initialize a manifest file and write the app details to it
echo '---' > $INTERROGATOR_MANIFEST
echo 'applications:' >> $INTERROGATOR_MANIFEST
echo "- name: $INTERROGATOR_APP_NAME" >> $INTERROGATOR_MANIFEST
echo "  instances: $INTERROGATOR_INSTANCES" >> $INTERROGATOR_MANIFEST
echo "  memory: ${INTERROGATOR_MEMORY}M" >> $INTERROGATOR_MANIFEST