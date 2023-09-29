#!/usr/bin/env bash
set -e
# Mirror Ubuntu releases directory

RSYNCSOURCE=rsync://ca.rsync.releases.ubuntu.com/ubuntu-releases
BASEDIR=/media/mirror/ubuntu/releases/

base_releases.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1

host="$(hostname -f)"
date -u > "${BASEDIR}/.trace/${host}" || exit 2