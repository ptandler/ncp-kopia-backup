#! /usr/bin/bash
#
# connect kopia to the repo at Storj via S3 connector
#

set -x

# read config, especially credentials from local file
source .env

kopia repository connect s3 \
        --bucket=${bucket} \
        --access-key=${access-key} \
        --secret-access-key=${secret-access-key} \
        --endpoint=gateway.storjshare.io \
        --description='Storj kopia repo'

# setup policies
kopia policy set \
  --add-dot-ignore '.kopiaignore' \
  --ignore-cache-dirs true \
  --one-file-system true \
  "$USER@$HOSTNAME"
#kopia  policy edit "@nextcloudpi"
