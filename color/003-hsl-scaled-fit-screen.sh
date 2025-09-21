#!/usr/bin/env bash

setBackgroundColor() {
    echo -en "\x1b[48;2;$1;$2;$3""m"
}

resetOutput() {
    echo -en "\x1b[0m\n"
}

# hsl_to_rgb H S L  -> echoes "R G B"
hsl_to_rgb() {
  local H=$1 S=$2 L=$3
  local scale=1000

  # normalize and scale
  H=$(( (H%360+360)%360 ))
  S=$(( S*10 ))            # 0..1000
  L=$(( L*10 ))            # 0..1000

  # C = (1 - |2L-1|)*S
  local twoL=$((2*L))
  local a=$(( twoL>1000 ? twoL-1000 : 1000-twoL ))   # |2L-1000|
  local C=$(( ( (1000 - a) * S + 500 ) / 1000 ))     # round

  # X = C*(1 - |(H/60 mod 2)-1|)
  local hsec=$(( (H*1000)/60 ))                      # H' * 1000
  local hmod=$(( hsec % 2000 ))
  local diff=$(( hmod>1000 ? hmod-1000 : 1000-hmod )) # |...-1| *1000
  local X=$(( ( C * (1000 - diff) + 500 ) / 1000 ))

  # m = L - C/2
  local m=$(( L - C/2 ))

  # choose sector
  local i=$(( H/60 ))
  local r1 g1 b1
  case $i in
    0) r1=$C; g1=$X; b1=0 ;;
    1) r1=$X; g1=$C; b1=0 ;;
    2) r1=0;  g1=$C; b1=$X ;;
    3) r1=0;  g1=$X; b1=$C ;;
    4) r1=$X; g1=0;  b1=$C ;;
    *) r1=$C; g1=0;  b1=$X ;;
  esac

  # scale to 0..255 with rounding
  local R=$(( ((r1 + m) * 255 + 500) / 1000 ))
  local G=$(( ((g1 + m) * 255 + 500) / 1000 ))
  local B=$(( ((b1 + m) * 255 + 500) / 1000 ))

  # clamp just in case
  ((R<0))&&R=0; ((R>255))&&R=255
  ((G<0))&&G=0; ((G>255))&&G=255
  ((B<0))&&B=0; ((B>255))&&B=255

  echo "$R $G $B"
}




# Function to restore terminal settings on exit
function restore_terminal {
  # Disable mouse tracking (DECSET 1000) and restore terminal
  echo -ne "\033[?1000l"
  # Restore echoing back to terminal
  stty echo
  tput cnorm # Show the cursor
}

# Trap the exit signal to ensure cleanup runs
trap restore_terminal EXIT

# Hide the cursor and save terminal settings
tput civis
# Do not echo input characters
stty -echo



# We are usign a zer0-based coordinate system
# so the maximum coordinate is one less than
# the number of columns/rows
width=$(( $(tput cols) - 1 ))
# Reduce height to leave room for the prompt at the end
height=$(( $(tput lines) - 2 ))

# For each row in the terminal
for row in `seq 0 $height`; do

  # the row represents the saturation
  # scale the saturation to 0..100 
  s=$(( row * 100 / height ))

  # For each column in this row
  for column in `seq 0 $width`; do

    # the column represents the hue
    # scale the hue to 0..360
    h=$(( column * 360 / width ))

    read r g b < <(hsl_to_rgb $h 50 $s)
    setBackgroundColor $r $g $b
    echo -en " "

  done
  resetOutput
done