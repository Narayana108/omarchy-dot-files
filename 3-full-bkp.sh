#!/bin/bash

SOURCE="/home/narayana"
DESTINATION="/run/media/narayana/agastya_rishi/backup-10-09-23"
EXCLUDE=( .cache .local .bun .deno .ghost \
    .librewolf go Public .wine .telegram-cli \
    .w3m .vmware .steam .npm .mozilla .wpscan )
#EXCLUDE=( /home/narayana/.cache/ /home/narayana/.local/ )

#INCLUDE=( '/.vim*' '/.git*' /.ssh .bash_aliases .bashrc )
#EXCLUDE=( '/VirtualBox_VMs/*/Snapshots'  /snap /Downloads '/.*' )

#include_opts=()
#for item in "${INCLUDE[@]}"; do
    #include_opts+=( --include="$item" )
#done

exclude_opts=()
for item in "${EXCLUDE[@]}"; do
    exclude_opts+=( --exclude="$item" )
done

rsync -aAXv --human-readable --progress --delete \
    "${exclude_opts[@]}" \
    $SOURCE \
    $DESTINATION

#rsync -aAXv --human-readable --progress --stats –-delete --dry-run \
    #"${exclude_opts[@]}" \
    #$SOURCE \
    #$DESTINATION \
    #| pv -lep -s 5

#rsync ${DRYRUNARG:+"$DRYRUNARG"} -avzhP --delete \
    #"${include_opts[@]}" \
    #"${exclude_opts[@]}" \
    #"${SOURCE_DIRS[@]}" \
    #"$MNTPNT/$DEST_DIR"
