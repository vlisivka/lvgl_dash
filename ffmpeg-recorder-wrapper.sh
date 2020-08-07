#!/bin/bash

FRAMERATE="5" # 10 is max for Dash
PRESET="veryfast"
FORMAT="mp4" # Or apng
TUNE="stillimage"
VIDEO_CODEC="libx264"
RECORDS_DIR="/data/screenshots"

# If ffmpeg is already started ...
PID="$(pidof ffmpeg)"
if [ -n "$PID" ]
then
  # ... then kill it.
  kill $PID
  
  # Play end beep
  event-server beep long_negative

else
  # Override defaults, if configuration file is present and not empty
  if [ -s /etc/ffmpeg-recorder.conf ]
  then
    . /etc/ffmpeg-recorder.conf || :
  fi

  # Play start beep
  event-server beep long_positive

  # Start ffmpeg
  FILENAME="$RECORDS_DIR/$(date +'%Y-%m-%d_%H-%M-%S').$FORMAT"
  exec ffmpeg -f fbdev -framerate "$FRAMERATE" -i /dev/fb0 -r "$FRAMERATE" -c:v "$VIDEO_CODEC" -preset "$PRESET" "$FILENAME"
fi
