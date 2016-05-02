#!/bin/sh
#
# status-display
#
# Usage:
#   in cmus command ":set status_display_program=status-display"
#
# This scripts is executed by cmus when status changes:
#   cmus-status-display key1 val1 key2 val2 ...
#
# All keys contain only chars a-z. Values are UTF-8 strings.
#
# Keys: status file url artist album discnumber tracknumber title date
#   - status (stopped, playing, paused) is always given
#   - file or url is given only if track is 'loaded' in cmus
#   - other keys/values are given only if they are available
#
#
# This script will be called by cmus upon every status change, and
# will call cmus-remote to implement a hacky 'album shuffle' mode!
#
# Matt Collins 02May2016

# set up 'mode' files:
if [ ! -f ~/.cmus/mode ]; then # to track whether we're playing an album, or changing
        echo "PLAYING" > ~/.cmus/mode
fi
if [ ! -f ~/.cmus/lastalbum ]; then # to track which album we're listening to.
        touch ~/.cmus/lastalbum
fi

# get all the status parts into local variables
while test $# -ge 2
do
	eval _$1='$2'
	shift
	shift
done
# ...and the current mode and album
mode=$(cat ~/.cmus/mode)
lastalbum=$(cat ~/.cmus/lastalbum)

#if [ "$_status" != "playing" ]; then # only do stuff if cmus is playing, not pausing etc
#	wall $_status
#	exit 1
#fi

#if test -n "$_file"; then
#wall yes
# now we do stuff...
# first, check if we're playing, or changing album
if [ "$mode" = "PLAYING" ]; then #playing an album
#	wall PLAYING
	# now we check if we've finished playing an album, and need to switch modes
	if [ "$lastalbum" = "$_album" ]; then # same album, so do nothing
		echo $_album > ~/.cmus/lastalbum
	else # new album, so change mode, switch shuffle on, and next track
		cmus-remote -v 0%
		echo "CHANGING" > ~/.cmus/mode
		cmus-remote -C "set shuffle=true"
		cmus-remote -n
	fi
else if [ "$mode" = "CHANGING" ]; then #changing album, and going back to first track
#	wall CHANGING
	#first, we need to turn off shuffle
	cmus-remote -C "set shuffle=false"
	#then set lastalbum
	echo $_album > ~/.cmus/lastalbum
	#set mode to 'back'
	echo "BACK" > ~/.cmus/mode
	#and finally go back one track
	cmus-remote -r
else #mode must be 'BACK', so go back one track at a time until we pass the first track
	if [ "$_album" = "$lastalbum" ]; then
		#haven't pased first track yet, so just go back one
		cmus-remote -r
	else # passed first track! so set mode Playing, and forward one track
		echo "PLAYING" > ~/.cmus/mode
		cmus-remote -v 80% -n
#		cmus-remote -n
	fi
fi
fi
