#!/bin/bash

source ./credentials

DATEAPP="date"
UNAME=`uname`
if [ $UNAME == "Darwin" ]; then
    DATEAPP="gdate"
fi

TODAY=`${DATEAPP} +%F`
MONTHAGO=`${DATEAPP} +%F --date="15 days ago"`
# echo $TODAY
DIRS=`cat ./directories`

for i in $DIRS; do
i=`echo $i | rev | cut -f 1 -d"/" | rev`
    FILENAME=${i##*/}
    DAYLIST=`aws s3 ls s3://$BUCKET/$FILENAME/`
    for j in $DAYLIST; do
        if [ "$j" != "PRE" ]; then
            CURRENTDAY=`echo $j | tr -s " " | cut -f2 -d" " | cut -f1 -d"/"`
            TODAY2=`$DATEAPP --date "$CURRENTDAY" +%s`
            CURRENTDAY2=`$DATEAPP --date "$MONTHAGO" +%s`
            if [ $CURRENTDAY2 -gt $TODAY2 ]; then
                echo "Removing ${FILENAME} for $CURRENTDAY ..."
                aws s3 rm --recursive s3://$BUCKET/$FILENAME/$CURRENTDAY
            else
                echo -n "."
            fi
        fi
    done
done
