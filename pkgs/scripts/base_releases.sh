#!/usr/bin/env bash
set -e
# Mirror some releases directory

RSYNCSOURCE="$1"
BASEDIR="$2"

fatal() {
  echo "$1"
  exit 1
}

if [ ! -d ${BASEDIR} ]; then
  fatal "${BASEDIR} does not exist ! Is the LXC mount ok ?"
fi

rsync -q --recursive --times --links --hard-links \
  --stats --delete-after \
  "$RSYNCSOURCE"  "$BASEDIR" || fatal "Rsync failed from ${RSYNCSOURCE} !"