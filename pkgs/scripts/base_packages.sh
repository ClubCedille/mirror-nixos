#!/usr/bin/env bash -e
# Mirror some packages. Adapted from https://wiki.ubuntu.com/Mirrors/Scripts

RSYNCSOURCE="$1"
BASEDIR="$2"

fatal() {
  echo "$1"
  exit 1
}

if [ ! -d ${BASEDIR} ]; then
  fatal "${BASEDIR} does not exist ! Is the LXC mount ok ?"
fi

@rsync@/bin/rsync -q --recursive --times --links --hard-links \
  --stats \
  --exclude "Packages*" --exclude "Sources*" \
  --exclude "Release*" --exclude "InRelease" \
  "${RSYNCSOURCE}" "${BASEDIR}" || fatal "First stage of sync failed."

@rsync@/bin/rsync -q --recursive --times --links --hard-links \
  --stats --delete --delete-before \
  "${RSYNCSOURCE}" "${BASEDIR}" || fatal "Second stage of sync failed."