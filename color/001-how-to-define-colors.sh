#!/usr/bin/env bash

# There are three ways to define colors on a modern terminal.
#
# Using the basic 8-color pallet

printf "\e[31m8 bit Red\e[0m"
printf "\n\n"

# Using a 256-color pallet

printf "\e[38;5;196m24 bit Red\e[0m"
printf "\n\n"

# Using 24 bit truecolor with rgb

printf "\e[38;2;200;10;10mTruecolor Red\e[0m"
