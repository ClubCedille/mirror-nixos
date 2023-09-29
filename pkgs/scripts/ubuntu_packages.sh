#!/usr/bin/env bash
set -e
# Mirror Ubuntu packages. Adapted from https://wiki.ubuntu.com/Mirrors/Scripts

RSYNCSOURCE=rsync://ca.archive.ubuntu.com/ubuntu
BASEDIR=/media/mirror/ubuntu/packages/

base_packages.sh "${RSYNCSOURCE}" "${BASEDIR}" || exit 1

host="$(hostname -f)"
date -u > "${BASEDIR}/project/trace/${host}" || exit 2