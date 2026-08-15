#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Sleep
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 😴
# @raycast.packageName Hue Lights

# Documentation:
# @raycast.description Turn on Jae's Room lights with the Sleepy scene
# @raycast.author jae

source "$(dirname "$0")/hue-common.sh"

curl -sk -X PUT "https://$BRIDGE_IP/api/$API_KEY/groups/$ROOM_GROUP/action" \
  -d '{"scene": "oYqCSjG6hkrA5BuT"}' > /dev/null

echo "Sleep"
