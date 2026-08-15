#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Relax
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🧘
# @raycast.packageName Hue Lights

# Documentation:
# @raycast.description Turn on Jae's Room lights with the Relax scene
# @raycast.author jae

source "$(dirname "$0")/hue-common.sh"

curl -sk -X PUT "https://$BRIDGE_IP/api/$API_KEY/groups/$ROOM_GROUP/action" \
  -d '{"scene": "Ji8hYlseUl4ETWv4"}' > /dev/null

echo "Relax"
