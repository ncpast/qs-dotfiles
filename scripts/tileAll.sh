#!/bin/bash

active_ws=$(hyprctl activeworkspace -j | jq -r '.id')

hyprctl clients -j | jq -r --arg ws "$active_ws" \
    '.[] | select(.workspace.id == ($ws | tonumber)) | .address' | \
while read -r addr; do
    hyprctl dispatch settiled "address:$addr"
done