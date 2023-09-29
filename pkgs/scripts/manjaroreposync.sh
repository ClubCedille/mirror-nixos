#!/usr/bin/env bash
set -e
# This script should be a cronjob and should be run a few times a day. (example for /etc/crontab: "0  *  *  *  * root /usr/bin/manjaroreposync").
# However you can also move this script to "/etc/cron.hourly".
# To be an official Manjaro Linux mirror and to get access to our rsync server, you have to tell us your static ip of your synchronization server.


RSYNCSOURCE="@manjaroRsyncSource@"
LOCKFILE="@lockFile@"
DESTPATH="@mirrorDirectory@"

# DESTPATH="/media/mirror/manjaro/"
# RSYNC=/usr/bin/rsync
# LOCKFILE=/tmp/rsync-manjaro.lock
# RSYNCSOURCE="rsync://rsync.mirrorservice.org/repo.manjaro.org/repos/"



synchronize() {
    rsync -rtlvH --delete-after --delay-updates --safe-links "$RSYNCSOURCE" "$DESTPATH"
}



if [ ! -e "$LOCKFILE" ]
then
    echo $$ >"$LOCKFILE"
    synchronize
else
    PID=$(cat "$LOCKFILE")
    if kill -0 "$PID" >&/dev/null
    then
        echo "Rsync - Synchronization still running"
        exit 0
    else
        echo $$ >"$LOCKFILE"
        echo "Warning: previous synchronization appears not to have finished correctly"
        synchronize
    fi
fi

rm -f "$LOCKFILE"