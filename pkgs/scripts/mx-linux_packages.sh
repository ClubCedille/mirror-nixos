#!/usr/bin/env bash -e

#RSYNC_PASSWORD="T1tpw4rstmr"
RSYNC_PASSWORD="$(cat @rsyncPasswordFile@)"

@rsync@/bin/rsync -rtv rsuser@iso.mxrepo.com::workspace /media/mirror/mx-linux/