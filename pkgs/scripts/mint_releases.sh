#!/usr/bin/env bash -e
# Mirror Linux Mint releases directory

RSYNCSOURCE=@mintReleasesRsyncSource@
BASEDIR=/media/mirror/linuxmint/releases/

@base_path@/base_releases.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1