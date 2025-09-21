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

# Get terminal dimensions
ROWS=$(tput lines)
COLS=$(tput cols)

# Function to print ASCII character for a given number
# Uses modulo to wrap around printable ASCII range (33-126)
print_ascii() {
    local num=$1
    # Map to printable ASCII range (33-126, 94 characters total)
    local ascii_code=$((33 + (num % 94)))
    printf "\\$(printf '%03o' $ascii_code)"
}

clear

# Print top row (columns)
for ((col=0; col<COLS; col++)); do
    print_ascii $col
done
echo

# Print left side (rows) - starting from row 1
# The first value to represent row 0 is already printed
# by the top row, so no need to repeat it.
for ((row=1; row<ROWS-1; row++)); do
    print_ascii $row
    echo
done