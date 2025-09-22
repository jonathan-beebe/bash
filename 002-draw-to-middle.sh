#!/usr/bin/env bash

# Print a messsge at the center of the screen

read -r rows cols < <(stty size)

x=$(($cols / 2))
y=$(($rows / 2))

# For more details on how to define and use colors see
# 004-colors.sh

orange='\033[38;5;214m'
purple='\033[38;5;93m'
reset='\033[0m'

msg="Center"
msg_length=${#msg}

printf '\033[%d;%dH%b%s%b\n' \
  "$((y - 1))" \
  "$((x - (msg_length / 2)))" \
  "$orange" \
  "$msg" \
  "$reset"

center_text="$x ✖️ $y"
center_text_length=${#center_text}

printf '\033[%d;%dH%b%s%b\n' \
  "$y" \
  "$((x - (center_text_length / 2)))" \
  "$purple" \
  "$center_text" \
  "$reset"

