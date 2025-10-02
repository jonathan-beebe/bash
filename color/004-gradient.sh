#!/usr/bin/env bash

# Gradients pulled from K-Pop Demon Hunters end credits
#
# ./gradient.sh #457be7 #dc74e4 #d94be3 #db4be3
# ./gradient.sh #d85c9a #79a599 #ce9f86 #6e90a2
# ./gradient.sh #a355d2 #0c8ac8 #c167cc #8a80d3
# ./gradient.sh #579b9b #d36796 #6e7497 #d2a0a0
# ./gradient.sh #ce9ea5 #86a0b9 #ad95c7 #b37aad
# ./gradient.sh #ce609e #6849ad #c75ec0 #c65fbe

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 #RRGGBB #RRGGBB #RRGGBB #RRGGBB"
    echo "Colors for: top-left top-right bottom-left bottom-right"
    exit 1
fi

hex_to_rgb() {
    local hex="${1#\#}"  # Remove # if present
    printf "%d %d %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# Parse corner colors
# The <<< is a "here string" that redirects 
# the value as input to a command.
# https://www.youtube.com/watch?v=0cWuZvw8lXc
read tl_r tl_g tl_b <<< $(hex_to_rgb "$1")
read tr_r tr_g tr_b <<< $(hex_to_rgb "$2")
read bl_r bl_g bl_b <<< $(hex_to_rgb "$3")
read br_r br_g br_b <<< $(hex_to_rgb "$4")

# Get terminal dimensions
width=$(tput cols) 
height=$(tput lines)

# Clear screen and hide cursor
tput civis

# Restore cursor on exit
trap 'tput cnorm' EXIT

# Bilinear interpolation
for ((y=1; y<(height - 1); y++)); do
    for ((x=0; x<width; x++)); do
        # Calculate normalized coordinates (0-1000 for integer math)
        fx=$((x * 1000 / (width-1)))
        fy=$((y * 1000 / (height-1)))
        
        # Interpolate top and bottom rows
        top_r=$(( (tl_r * (1000-fx) + tr_r * fx) / 1000 ))
        top_g=$(( (tl_g * (1000-fx) + tr_g * fx) / 1000 ))
        top_b=$(( (tl_b * (1000-fx) + tr_b * fx) / 1000 ))
        
        bot_r=$(( (bl_r * (1000-fx) + br_r * fx) / 1000 ))
        bot_g=$(( (bl_g * (1000-fx) + br_g * fx) / 1000 ))
        bot_b=$(( (bl_b * (1000-fx) + br_b * fx) / 1000 ))
        
        # Interpolate between top and bottom
        r=$(( (top_r * (1000-fy) + bot_r * fy) / 1000 ))
        g=$(( (top_g * (1000-fy) + bot_g * fy) / 1000 ))
        b=$(( (top_b * (1000-fy) + bot_b * fy) / 1000 ))
        
        # Output ANSI color without reset after each char
        printf "\033[48;2;%d;%d;%dm " "$r" "$g" "$b"
    done
    printf "\033[0m"  # Reset at end of line
done

exit 0