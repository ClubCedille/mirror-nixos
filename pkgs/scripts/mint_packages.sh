#!/usr/bin/env bash -e
# Mirror Linux Mint packages

RSYNCSOURCE=@mintPackagesRsyncSource@
BASEDIR=@mirrorDirectory@

#BASEDIR=/media/mirror/linuxmint/packages/

@base_path@/base_packages.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1