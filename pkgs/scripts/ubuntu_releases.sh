#!/usr/bin/env bash -e
# Mirror Ubuntu releases directory

RSYNCSOURCE=rsync://ca.rsync.releases.ubuntu.com/ubuntu-releases
BASEDIR=/media/mirror/ubuntu/releases/

@base_path@/base_releases.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1

host=$(/bin/hostname -f)
date -u > "${BASEDIR}/.trace/${host}" || exit 2