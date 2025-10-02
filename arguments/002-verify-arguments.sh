#!/usr/bin/env bash

# I want a script that will validate the arguments and if they do not pass
# then it will echo the instructions for how to invoke the script.
#
# In this case, we will take in a string that should be a hexadecimal color
# formatted as `#FFFFFF`.

# Noteable bash features used:
#
# Heredocs, the `<<` symbols, used to redirect multi-line output
# https://www.youtube.com/watch?v=-a1VAole01s
#
# The seemingly nameless `=~` operator which pairs with the `[[…]]` expression
# to perform a regex match of the string on the right side, giving us a boolean
# value of 0 signaling it does match or a 1 signaling it does-not match.
# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#index-_005b_005b
#
# Print instructions
usage() {
    cat <<EOF
Usage: $0 <color>

This script requires exactly one color argument.

Arguments:
  color    Any hexidecimal string representing a color

Examples:
  $0 #FF0000
  $0 "#FF0000"

EOF
    exit 1
}

is_not_hex_color() {
    local color="$1"
    # $color will be 0 if the regex matches or 1 if it does not
    # and the ! negates this to return the opposite signal.
    ! [[ "$color" =~ ^#[0-9A-Fa-f]{6}$ ]]
}

validate_args() {
  # Note that within the function $# refers to the function’s arguments
  # not the scripts. You must call this function with "$@" to pass in
  # the scripts arguments for this check to work.

  # Check that we have the right count of arguments.
  if [[ $# -ne 1 ]]; then
    return 1
  fi

  if is_not_hex_color "$1"; then
    return 1
  fi

  return 0
}

if validate_args "$@"; then
  echo "You provided a valid color argument $1"
else
  usage
fi