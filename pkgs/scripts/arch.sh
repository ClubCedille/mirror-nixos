#!/usr/bin/env bash
set -e
# Mirror Archlinux

RSYNCSOURCE=@archRsyncSource@
BASEDIR=@mirrorDirectory@

#RSYNCSOURCE=rsync://mirror.csclub.uwaterloo.ca/archlinux/
#BASEDIR=/media/mirror/archlinux/

fatal() {
  echo "$1"
  exit 1
}

if [ ! -d ${BASEDIR} ]; then
  fatal "${BASEDIR} does not exist ! Is the LXC mount ok ?"
fi

rsync -rtlvH --stats --delete-after --delay-updates --safe-links \
  "${RSYNCSOURCE}" "${BASEDIR}" || fatal "First stage of sync failed."