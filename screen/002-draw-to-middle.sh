#!/usr/bin/env bash

# x, y, message, color
draw_center() {
  local x="$1"
  local y="$2"
  local msg="$3"
  local msg_length=${#msg}
  local color="$4"
  local reset='\033[0m'

  printf '\033[%d;%dH%b%s%b\n' \
    "$y" \
    "$((x - (msg_length / 2)))" \
    "$color" \
    "$msg" \
    "$reset"
}

cmd() {
  arg="$1"
  printf '%b' "$arg"
}

orange='\033[38;5;214m'
purple='\033[38;5;93m'
clear='\033[2J'
reset='\033[0m'

screen_width=$(tput cols)
screen_height=$(tput lines)

X=$(($screen_width / 2))
Y=$(($screen_height / 2))

cmd $clear

# Print a messsge at the center of the screen

msg="Center"
draw_center "$X" "$((Y - 1))" "$msg" "$orange"

center_text="$X ✖️ $Y"
draw_center "$X" "$Y" "$center_text" "$purple"

# Reset cursor to bottom of screen
tput cup $((screen_height-1)) $((screen_width-1))
cmd $reset