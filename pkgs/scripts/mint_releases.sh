#!/usr/bin/env bash
set -e
# Mirror Linux Mint releases directory

RSYNCSOURCE=@mintReleasesRsyncSource@
BASEDIR=/media/mirror/linuxmint/releases/

base_releases.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1
