#!/usr/bin/env bash

# $# is a special variable containing the number of arguments

if [[ $# -ne 4 ]]; then
    echo "Error: Expected 4 arguments, got $#"
    exit 1
fi