#!/usr/bin/env bash
set -e
# Mirror Linux Mint packages

RSYNCSOURCE=@mintPackagesRsyncSource@
BASEDIR=@mirrorDirectory@

#BASEDIR=/media/mirror/linuxmint/packages/

base_packages.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1
