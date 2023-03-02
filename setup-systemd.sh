#! /bin/bash
#
# setup the systemd services here
#

# create symlinks for units
ln -s -f /home/kopia/systemd/* /etc/systemd/system/

# enable timers
systemctl enable kopia-backup.timer kopia-backup-full.timer
