#!/bin/bash
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
    FILENAME=${i##*/}
    tar zcvf ${FILENAME}.tar.gz $i
    aws s3 cp /tmp/${FILENAME}.tar.gz s3://${BUCKET}/${FILENAME}/${TODAY}/backup.tar.gz
    rm -rf /tmp/${FILENAME}.tar.gz
done