# Regular backup Nextcloud server running with NCP (NextcloudPi) using kopia and Storj cloud storage

Some scripts to backup your local nextcloud instance running on a Raspberry Pi (or alike) with nextcloudpi.

## Requirements

This scripts uses:

- the wonderful [kopia](https://kopia.io/) for backup (end-to-end encrypted, incremental, de-dup (using hashes and splitting to save only changed parts of large files), compressed, fast!)
- optional: use [zstd](https://facebook.github.io/zstd/) to compress DB dumps (gzip otherwise)
- save backup to [Storj cloud storage](https://www.storj.io/) (but you could connect to another kopia repository if you want, of course. *However, Storj currently offers 150 GB for free and is cheaper than all other providers I found. And I like the idea of the distributed approach with *[open source software](https://github.com/Storj/)* that anyone can use and sign up to host another Storj node. I don't really understand the *[details of 'erasure codes' as redundancy approach](https://docs.storj.io/dcs/concepts/file-redundancy)* 🤔, *but it sounds to me like someone really thought in depth about this...* :face_with_peeking_eye:)

## Installation

- the files in this repo should be checked out to `/home/kopia` as some paths are hardcoded...
- create your kopia repository, e.g. at Storj
- connect to the kopia repository, e.g. using `storj-connect-repo.sh`
  - in this case you should write your `.env` file containing your credentials
- NOTE: currently you need to adjust the paths in `kopia-run-backup.sh`
- setup and enable systemd timers by running `setup-systemd.sh`

## Usage

The timers run the `kopia-run-backup.sh` as root (which you also could run manually). No user interaction is required.

The script supports two modes: normal (executed every 4 hours) and full (daily).

### Normal Backup

This will backup

- compressed mysql DB dump (using zstd if available, gzip otherwise)
- nextcloud's data dir, containing all files
- the backup setup at `/home/kopia`
- complete system backup including the nextcloud from `/`

### Full Backup

In addition to the normal backup, this

- sets nextcloud's maintenance mode to avoid any action to produce an inconsistent state
- shutdown mysql and snapshot the DB directory (and restart mysql afterwards)
- restore maintenance mode to what it was before

## Sample .env

```sh
bucket=kopia
access-key=... your credentials from Storj...
secret-access-key=... your credentials from Storj...
```
