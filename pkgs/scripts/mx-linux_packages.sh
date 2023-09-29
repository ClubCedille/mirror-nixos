#!/usr/bin/env bash
set -e

#RSYNC_PASSWORD="T1tpw4rstmr"
RSYNC_PASSWORD="$(cat @rsyncPasswordFile@)"

rsync -rtv rsuser@iso.mxrepo.com::workspace /media/mirror/mx-linux/