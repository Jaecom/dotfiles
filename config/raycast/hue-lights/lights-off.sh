#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Lights Off
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🌑
# @raycast.packageName Hue Lights

# Documentation:
# @raycast.description Turn off Jae's Room lights
# @raycast.author jae

source "$(dirname "$0")/hue-common.sh"

curl -sk -X PUT "https://$BRIDGE_IP/api/$API_KEY/groups/$ROOM_GROUP/action" \
  -d '{"on": false}' > /dev/null

echo "Lights off"
