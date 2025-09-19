#!/usr/bin/env bash

SCREEN_WIDTH=$(tput cols)
SCREEN_HEIGHT=$(tput lines)

X=$(($SCREEN_WIDTH / 2))
Y=$(($SCREEN_HEIGHT / 2))

# Print a messsge at the center of the screen

orange='\033[38;5;214m'
purple='\033[38;5;93m'
reset='\033[0m'

msg="Center"
msg_length=${#msg}

printf '\033[%d;%dH%b%s%b\n' \
  "$((Y - 1))" \
  "$((X - (msg_length / 2)))" \
  "$orange" \
  "$msg" \
  "$reset"

center_text="$X ✖️ $Y"
center_text_length=${#center_text}

printf '\033[%d;%dH%b%s%b\n' \
  "$Y" \
  "$((X - (center_text_length / 2)))" \
  "$purple" \
  "$center_text" \
  "$reset"