#! /usr/bin/bash
#
# kopia repository must be setup and connected
# ensure that init-backup.sh has been run before!
#

set -x -e -E

#
# in "full_mode":
#  - enable mainenance mode,
#  - save DB dir (includes start and stop of mysql service)
#
# the normal "quick" mode could snapshot an inconsistent state
#
# TODO: use btrfs snapshots instead of maintenance mode and start/stop mysql?
#

full_mode=0
if [ "$1" = "--full" ]; then
  full_mode=1
fi

# load NCP helpers
source /usr/local/etc/library.sh

# TODO: get config from NC or NCP

DB_DIR=/media/myCloudDrive/ncdatabase
DB_BAK=/media/myCloudDrive/nc-db-backup.sql
DATA_DIR=/media/myCloudDrive/ncdata/data


if [ -z "$NCVER" ]; then
  NCVER=$(${ncc} --version 2>/dev/null || grep \$OC_VersionString /var/www/nextcloud/version.php | cut -d= -f2 | cut -d\' -f2)
  #NCVER=$(sudo -u www-data php /var/www/nextcloud/occ --version)
fi

source /etc/os-release

host=$(hostname)

comment="$NCVER @$host $PRETTY_NAME $(uname -r)"

echo "Run kopia backup for $comment"

# stop nextcloud

if [ "$full_mode" = 1 ]; then
  save_maintenance_mode
  cleanup(){ local ret=$?; restore_maintenance_mode; exit $ret; }
  trap cleanup EXIT INT TERM HUP ERR
  ncc maintenance:mode --on
fi

# create and backup DB dump

if command -v zstd > /dev/null; then
  DB_BAK="$DB_BAK.zst"
  # zstd: -17 seems to be a bit better than -16; see `zstd -b1 -e20 nc-db-backup.sql`
  #           funny enough, -1 (ratio about 5.1 and MUCH faster) is the next best choice after -16 (ratio about 5.9)
  #       -f = force overwrite needed with -o
  #       -T0 = auto-detect number of cores to use
  mysqldump --all-databases | zstd -17 -T0 --sparse -f -o "$DB_BAK"
else
  DB_BAK="$DB_BAK.gz"
  mysqldump --all-databases | gzip > "$DB_BAK"
fi
kopia snapshot create --description "$comment" "$DB_BAK"

# backup database files

if [ "$full_mode" = 1 ]; then
  systemctl stop mysql
  kopia snapshot create --description "$comment" "$DB_DIR"
  systemctl start mysql &
fi

# backup data

kopia snapshot create --description "$comment" "$DATA_DIR"

# restore maintenance mode to what is was before

if [ "$full_mode" = 1 ]; then
  restore_maintenance_mode
fi

# and finally do a system backup

# backup config
kopia snapshot create --description "$comment" /home/kopia

# backup system including nextcloud installation
kopia snapshot create --description "$comment" /
