#!/usr/bin/env bash

# I fint it *fasctinating* how the x10 protocol streams mouse events
# to the terminal. I have not found any official documentation on it,
# but have pieved things together through experimentation and reading
# various online resources.
#
# Like everthing else, the terminal streams characters to represent the
# mouse event. In the X10 protocol, a mouse event looks like this for a 
# click at column 2, row 1:
#
# `\E[M#"!`
#
# The actual coordinates are zero based.
# `"` is 1, representing a click on the second column.
# `!` is 0, representing a click on the first row.
#
# Taking this entire sequence apart, we have:
#
# ```
# \E[  - Escape sequence introducer.
# M    - Indicates a mouse event
# #    - Indicates a button press (32 for left click, 33 for middle, 34 for right)
# "    - Column + 32 (so column 2 is 34, which is the ASCII character ")
# !    - Row + 32 (so row 1 is 33, which is the ASCII character !)
# ```
#
# The official format is often documented as:
#
# ```
# ^[[Mabc
# ```
#
# In bash `^[` and `\E` both represent the escape character.
# I often see it officially documented as `^[` but `\E` is how
# it actually looks when printed in the terminal.
#
# - The starting `^[[M`` is the control sequence for mouse events.
# - The `a` is the button code (32 for left click, 33 for middle, 34 for right)
# - The `b` is the column + 32
# - The `c` is the row + 32
# 
# The values for `a`, `b`, and `c` all have 32 added so that they
# fall within the range of printable ASCII characters.
#
# So, now that we know what a mouse event looks like, we can print 
# the ASCII character corresponding to the row and column numbers
# of the terminal window. 
#
# Now we have two more limitations to contend with.
#
# 1. There are only 94 prointable ASCII characters (from 33 to 126).
#    This means if we record a mouse event beyond column 94 or row 94,
#    the values in this demo will wrap around.
# 2. We are limited to 223 columns and rows, because 223 + 32 = 255,
#    which is the maximum value for a byte. ((source)[https://github.com/xtermjs/xterm.js/issues/1962])
#
# Given all that, here is what our demo will look like for a terminal window 
# that is 80 columns wide and 20 tall.
#
# ```
# !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnop
# "
# #
# $
# %
# &
# '
# (
# )
# *
# +
# ,
# -
# .
# /
# 0
# 1
# 2
# 3
# ```
#
# So, for example, [!, !] is the top-left corner, which is {x:0, y:0}
# And [&, $] is {x:5, y:3}

function draw() {
    # Get terminal dimensions
    ROWS=$(tput lines)
    COLS=$(tput cols)

    x=$1  # column to highlight
    y=$2  # row to highlight

    bold_text='\e[1m'
    normal_text='\e[22m'

    fg="\e[38"
    bg="\e[48"

    white="2;255;255;255m"
    black="2;0;0;0m"

    # experimenting with color pallets extracted from these lidar images
    # https://kottke.org/23/09/stunning-high-resolution-lidar-images-of-rivers-deltas

    purple="2;59;51;111m"
    tan="2;203;146;120m"

    wine="2;33;22;36m"
    orange="2;158;78;59m"

    sky_blue="2;46;76;99m"
    yellow="2;213;146;76m"

    cl="${normal_text}${bg};${purple}${fg};${white}" # regular cell
    hl="${bold_text}${bg};${tan}${fg};${black}"      # highlighted cell
    
    reset='\e[0m'

    # start synchronized update (no tear on kitty/wezterm/foot/iTerm2, etc.)
    printf '\e[?2026h'

    # Function to print ASCII character for a given number
    print_ascii() {
        local num=$1
        local ascii_code=$((33 + (num % 94)))
        printf "\\$(printf '%03o' $ascii_code)"
    }

    # 1. Fill entire screen with background color
    printf '\e[H\e[2J'  # Clear and home
    printf "${cl}%*s" $((ROWS * COLS)) ""

    # 2. Draw the highlight column
    for ((r=1; r<=ROWS; r++)); do
        printf "\e[${r};${x}H${hl} "
    done

    # 3. Draw the highlight row
    printf "\e[${y};1H"
    printf "${hl}%*s" $COLS ""

    # 4. Draw axis labels on top of background
    # Top row (column labels)
    printf "\e[1;1H"  # Move to top row
    for ((col=0; col<COLS; col++)); do
        # Set color based on whether this is in the highlight column
        if [[ $col -eq $(( x - 1 )) ]]; then
            printf "${hl}"
        else
            printf "${cl}"
        fi
        print_ascii $col
    done

    # Left column (row labels)
    for ((row=1; row<ROWS; row++)); do
        printf "\e[${row};1H"  # Move to beginning of each row
        # Set color based on whether this is the highlight row
        if [[ $row -eq $y ]]; then
            printf "${hl}"
        else
            printf "${cl}"
        fi
        print_ascii $((row-1))
    done

    # 5. Move cursor to bottom and reset
    tput cup $((ROWS-1)) $((COLS-1))
    printf "$reset"

    # end synchronized update
    printf '\e[?2026l'
}

# Function to restore terminal settings on exit
function restore_terminal {
    ROWS=$(tput lines)

    tput cup "$(( ROWS - 1 ))" "0"

    # reset output
    echo -en "\x1b[0m\n"

    # Disable mouse tracking
    echo -ne "\033[?1000l"

    # Restore echoing back to terminal
    stty echo

    # Show the cursor
    tput cnorm

    printf "\e[?25h\e[?1049l"   # show cursor and leave alt screen

    exit 0
}

# Trap the exit signal to ensure cleanup runs
trap restore_terminal EXIT

# Hide the cursor and save terminal settings
tput civis
# Do not echo input characters
stty -icanon -echo

# Enable mouse tracking modes
echo -ne "\033[?1000h"

printf '\e[?1049h\e[?25l'               # enter alt screen, hide cursor

draw "0" "0"

# Read mouse input in a loop
while true; do
  # Read the escape sequence for a mouse event
  # -n 6: Read exactly 6 characters, which is the expected length for a click event
  read -n 6 -s line

  # A mouse click event looks like ^[[Mabc where a=32 for a left click,
  # and b and c are the column and row + 32, respectively.
  # Convert character to ASCII value and subtract 32
  button=$(printf "%d" "'${line:3:1}")
  col=$(printf "%d" "'${line:4:1}")
  row=$(printf "%d" "'${line:5:1}")

  # The decoded values are the ASCII value minus 32
  col=$((col - 32))
  row=$((row - 32))

  # Check for a left click (mouse button 1) and valid coordinates
  if [ "$button" -eq 32 ] && [ "$row" -gt 0 ] && [ "$col" -gt 0 ]; then
    draw "$col" "$row"
  fi
done

