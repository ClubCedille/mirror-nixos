#!/usr/bin/env bash -e
# Mirror Ubuntu packages. Adapted from https://wiki.ubuntu.com/Mirrors/Scripts

RSYNCSOURCE=rsync://ca.archive.ubuntu.com/ubuntu
BASEDIR=/media/mirror/ubuntu/packages/

@base_path@/base_packages.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1

host=$(/bin/hostname -f)
date -u > "${BASEDIR}/project/trace/${host}" || exit 2