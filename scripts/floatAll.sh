#!/bin/bash

active_ws_json=$(hyprctl activeworkspace -j)
active_ws=$(echo "$active_ws_json" | jq -r '.id')
monitor_name=$(echo "$active_ws_json" | jq -r '.monitor')

monitor_json=$(hyprctl monitors -j | jq -r --arg mon "$monitor_name" '.[] | select(.name == $mon)')
mon_width=$(echo "$monitor_json" | jq -r '.width')
mon_height=$(echo "$monitor_json" | jq -r '.height')
mon_x=$(echo "$monitor_json" | jq -r '.x')
mon_y=$(echo "$monitor_json" | jq -r '.y')

target_width=$(( mon_width * 40 / 100 ))
target_height=$(( mon_height * 40 / 100 ))


hyprctl clients -j | jq -r --arg ws "$active_ws" \
    '.[] | select(.workspace.id == ($ws | tonumber)) | .address' | \
while read -r addr; do
    hyprctl dispatch setfloating "address:$addr"
    hyprctl dispatch resizewindowpixel exact "$target_width" "$target_height",address:"$addr"
done