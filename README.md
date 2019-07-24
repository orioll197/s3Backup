# S3 Backup System 💾

<br>This script lets you back up any folder and it's content into an s3 bucket
<br>Based on [Kyngo's code](https://github.com/Kyngo/S3Backup)

## Installation / Setup

1. Copy all the files in here to `/opt/s3backup` on your machine.
2. Then change the permissions of the scripts so they can be executed, like this: `chmod +x /opt/s3backup/{backup,delete}.sh`.
3. Then `cp /opt/s3backup/credentials.dist /opt/s3backup/credentials`, and then put your AWS programatic credentials, prefered region and the MYSQL credentials for the SQL backup inside that file.
4. Finally, create a file named `directories` inside the project folder, and add each directory to backup, one per line with no slashes at the end. Then you can follow it with `-->` and the name of a ddbb you may want to backup!

### Line without Database to backup
`/directory/to/backup`

### Line with Database to backup
`/directory/to/backup-->ddbb_name`

Easy as pie! 🥧

## Cron to run script ⏱

`0 0 * * * root test -x /opt/s3backup/backup.sh && bash /opt/s3backup/backup.sh`<br>
`0 2 * * * root test -x /opt/s3backup/delete.sh && bash /opt/s3backup/delete.sh`

## Restoring

There is also a script called `restore.sh` which will assist you on restoring a lost project.
