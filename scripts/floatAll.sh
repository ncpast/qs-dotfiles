#!/bin/bash

active_ws_json=$(hyprctl activeworkspace -j)
active_ws=$(echo "$active_ws_json" | jq -r '.id')
monitor_name=$(echo "$active_ws_json" | jq -r '.monitor')

monitor_json=$(hyprctl monitors -j | jq -r --arg mon "$monitor_name" '.[] | select(.name == $mon)')

# Minimum size = 1/4 of the monitor, in logical pixels (physical res / scale)
min_w=$(echo "$monitor_json" | jq -r '(.width  / .scale / 4) | floor')
min_h=$(echo "$monitor_json" | jq -r '(.height / .scale / 4) | floor')

# Sizes and floating state are read up front, before anything gets changed
hyprctl clients -j | jq -r --arg ws "$active_ws" \
    '.[] | select(.workspace.id == ($ws | tonumber)) | [.address, .floating, .size[0], .size[1]] | @tsv' | \
while read -r addr floating w h; do
    # Already floating: leave it completely alone (no float, no resize)
    [[ "$floating" == "true" ]] && continue

    w=$(( w - 60 ))
    h=$(( h - 60 ))
    (( w < min_w )) && w=$min_w
    (( h < min_h )) && h=$min_h

    hyprctl dispatch "hl.dsp.window.float({ action = \"set\", window = \"address:$addr\" })"
    hyprctl dispatch "hl.dsp.window.resize({ x = $w, y = $h, relative = false, window = \"address:$addr\" })"
    hyprctl dispatch 'hl.dsp.window.move({ x = 0, y = 16, relative = true })'   # 32 / 2: compensate for the title bar
done