#!/usr/bin/env bash

# To start, I want to know how to accesss the canvas. Everything will be done
# within this rectangle so I need to know how to measure it.
#
# My first learning is there are multiple ways to measure the size of a terminal canvas.
# And we don't use x & y, we use columns & lines or rows.
#
# Throughout the other scripts I will generally favor a pure bash approach
# where available, but may explore other options like this just to compare.

echo "Measuring the screen size using 'tput', an external program"
printf "columns: %d\n" $(tput cols)
printf "lines:   %d\n" $(tput lines)

echo ""

echo "Measuring the screen size using 'stty', a pure bash approach"
read -r rows cols < <(stty size)
printf "columns: %d\n" $cols
printf "lines:   %d\n" $rows

# I had never seen the < <(...) syntax.
#
# The first `<` is a standard input redirection. You may be familiar with this
# if you have ever diverted the output of bash command to a file, e.g.
#
# `echo "Hello World! > output.txt`
#
# This takes the output of the left side and passes it as input to the right.
#
# Well, when reversed it reads the output of the right side and use it as
# input to the left side.
#
# Then the `<(...)` is a sub command, a process substitution, where the command inside
# the (...) is run, the output fed into a temp file, and the temp file substituted.
#
# Go ahead, try to run `stty size` on your terminal. It simply prints the two numbers.
# This is the same text that is then passed as input to the read command so it can
# set them as variables.
