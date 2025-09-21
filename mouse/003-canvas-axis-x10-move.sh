#!/usr/bin/env bash

# Riffing off of 002-canvas-axis-x10-click.sh
# and incorporating ../screen/003-draw-to-alt-screen.sh.
#
# Draw the axis for the entire screen, then track mouse movement
# and draw a crosshair at the current coordinate. This script
# attempts to track mouse events in a non-blocking way. Because
# drawing can take time and lags the mouse events, we try to 
# discard mouse events that occur while the screen is actively drawing
# and only capture the next mouse move coordinates after a draw cycle
# has finished.

# I find it *fasctinating* how the x10 protocol streams mouse events
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

# Store latest mouse position
mouse_x=0
mouse_y=0

# Flush all pending input
flush_input() {
    while read -t 0; do
        read -r -n1 -t 0.001 || break
    done
}

# Read latest mouse position (non-blocking)
read_mouse() {
    local got_position=0
    
    # Read all available input, keeping only the last mouse position
    while read -t 0; do
        if IFS= read -r -n1 -t 0.001 char; then
            if [[ $char == $'\e' ]]; then
                local seq=$char
                while IFS= read -r -n1 -t 0.001 next; do
                    seq+=$next
                    [[ $next =~ [Mm] ]] && break
                done
                
                # Parse SGR format: \e[<button;col;row(M or m)
                IFS=';' read -r button col row <<< "${seq:3:-1}"
                
                # Update position
                if [[ -n $col && -n $row ]]; then
                    mouse_x=$col
                    mouse_y=$row
                    got_position=1
                fi
            fi
        else
            break
        fi
    done
    
    return $((1 - got_position))  # Return 0 if we got a position
}

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

    cl="${normal_text}${bg};${sky_blue}${fg};${white}" # regular cell
    hl="${bold_text}${bg};${yellow}${fg};${black}"     # highlighted cell
    
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
    printf '\e[H'  # go home (do not clear becasue we are in alt screen)
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

start_alt_screen() {
  # Enter alternate screen
  printf '\033[?1049h'

  # Clear screen
  printf '\033[2J'

  # Hide cursor
  printf '\033[?25l'
}

# Function to restore terminal settings on exit
function restore_terminal {
    # Leave alternate screen FIRST
    printf '\033[?1049l'

    # Then restore everything else
    printf "\e[?1000l"  # Disable basic mouse tracking
    printf "\e[?1003l"  # Disable all mouse motions
    printf "\e[?1006l"  # Disable SGR extended mode
    printf "\x1b[0m"     # Reset colors
    printf '\033[?25h'   # Show cursor
    
    stty echo icanon     # Restore terminal settings
    
    exit 0
}

# Trap the exit signal to ensure cleanup runs
trap restore_terminal EXIT

start_alt_screen

# Main draw loop
main() {
    # Setup terminal
    tput civis          # Hide cursor
    stty -echo -icanon min 0 time 0  # Non-blocking read
    
    # Enable SGR mouse tracking
    printf "\e[?1000h"  # Enable basic mouse tracking
    printf "\e[?1003h"  # Enable all mouse motions
    printf "\e[?1006h"  # Enable SGR extended mode
    
    # clear
    
    local last_x=-1
    local last_y=-1

    draw "0" "0"
    
    # Draw loop
    while true; do
        # Check for new mouse position
        if read_mouse; then
            # Only draw if position changed
            if [[ $mouse_x != $last_x || $mouse_y != $last_y ]]; then
                last_x=$mouse_x
                last_y=$mouse_y
                
                # Clear old events before drawing
                flush_input
                
                # Do the heavy draw
                draw "$mouse_x" "$mouse_y"
            fi
        fi
        
        # Small delay to prevent CPU spinning
        sleep 0.05
    done
}

main