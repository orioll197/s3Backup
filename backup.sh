#!/bin/bash
hash mysqldump 2>/dev/null || { echo >&2 "You need to install mysqldump to continue. Aborting."; exit 1; }

source ./credentials

DATEAPP="date"
UNAME=`uname`
if [ $UNAME == "Darwin" ]; then
    DATEAPP="gdate"
fi

TODAY=`${DATEAPP} +%F`
DIRS=`cat ./directories`

if aws s3api head-bucket --bucket $BUCKET 2>/dev/null; then 
    echo "Bucket found, continuing."
else 
    echo "Bucket does not exist. Proceeding to create it and perform backup on next execution."
    aws s3api create-bucket --bucket $BUCKET --region=eu-west-3 --create-bucket-configuration LocationConstraint=eu-west-3
    exit 0
fi 

cd /tmp
for i in $DIRS; do
    DDBB_NAME=${i#*-->}
    DIRECTORY=${i%-->*}
    FILENAME=${DIRECTORY##*/}
    tar zcvf ${FILENAME}.tar.gz $DIRECTORY
    mysqldump -h $DDBB_ENDPOINT  -u $DDBB_USER -p$DDBB_PASSWORD --port=$DDBB_PORT     --single-transaction     --routines     --triggers     --databases  $DDBB_NAME > ${DDBB_NAME}.sql
    aws s3 cp /tmp/${FILENAME}.tar.gz s3://${BUCKET}/${FILENAME}/${TODAY}/backup-${FILENAME}-${TODAY}.tar.gz
    aws s3 cp /tmp/${DDBB_NAME}.sql s3://${BUCKET}/${FILENAME}/${TODAY}/backup-${DDBB_NAME}-${TODAY}.sql
    rm -rf /tmp/${FILENAME}.tar.gz
    rm -rf /tmp/${DDBB_NAME}.sql
done