#!/usr/bin/env bash

start_alt_screen() {
  # Enter alternate screen
  printf '\033[?1049h'

  # Clear screen
  printf '\033[2J'

  # Hide cursor
  printf '\033[?25l'
}

end_alt_screen() {
    printf '\033[?25h'  # Show cursor
    printf '\033[?1049l' # Leave alternate screen
}

# Trap to restore terminal on exit
cleanup() {
  end_alt_screen
}

trap cleanup EXIT

start_alt_screen

# Draw something
printf '\033[H'  # Move to top-left
printf "Alternate Screen Demo\n"
printf "Press any key to exit..."

# Move cursor and draw a box
printf '\033[5;5H┌────────────┐'
printf '\033[6;5H│   Hello!   │'
printf '\033[7;5H└────────────┘'

# Wait for input
read -n1 -s