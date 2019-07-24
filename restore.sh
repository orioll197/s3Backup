#!/bin/bash

source ./credentials
source ./vars

DATEAPP="date"
UNAME=`uname`
if [ $UNAME == "Darwin" ]; then
    DATEAPP="gdate"
fi

TODAY=`${DATEAPP} +%F`
DIRS=`cat ./directories`
DIRS=$DIRS" EXIT"

function _Restore() {
    if [ -f /tmp/backup.tar.gz ]; then
        echo "Removing previous backup file..."
        rm -rf /tmp/backup.tar.gz
    fi
    
    DDBB_NAME=${1#*-->}
    DIRECTORY=${1%-->*}
    FILENAME=${DIRECTORY##*/}
    
    if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then 
        echo "Bucket found, looking for latest backup..."
        LATEST=`aws s3 ls s3://$BUCKET/$FILENAME/ | tr "\n" " " | tr -s " " | rev | cut -f 2 -d " " | rev | cut -f1 -d "/"`
        echo "Latest backup found is from ${bold}$LATEST${endbold}."
        # echo "Latest backup found is $LATEST. Downloading..."
        read -p "Do you want to restore this backup? (y/n): " -r

        if [[ $REPLY =~ ^[Yy]$ ]]; then

            OPTIONS=`aws s3 ls s3://$BUCKET/$FILENAME/$LATEST/ | awk '{print $4}'`

            FLAG_DDBB=false
            FLAG_TAR=false

            for OPTION in $OPTIONS; do
                FILE_EXT=${OPTION#*.}
                if [[ $FILE_EXT == "sql" ]];then
                    FLAG_DDBB=true
                elif [[ $FILE_EXT == "tar.gz" ]]; then
                    FLAG_TAR=true
                fi
            done

            OPTION=0
            OPTION_TEXT="nothing"

            if [[ $FLAG_DDBB == true ]] && [[ $FLAG_TAR == true ]];then
                PS3='Choose what do you want to restore: '
                MENU="Database Directory Both EXIT"

                select opt in $MENU;do
                    case $opt in
                        "Database") 
                            OPTION=1
                            OPTION_TEXT="the database $bold$yellow$DDBB_NAME$endcolor$endbold"
                            break
                            ;;
                        "Directory") 
                            OPTION=2
                            OPTION_TEXT="the directory $bold$yellow$DIRECTORY$endcolor$endbold"
                            break
                            ;;
                        "Both") 
                            OPTION=3
                            OPTION_TEXT="both the database ($bold$yellow$DDBB_NAME$endcolor$endbold) and the directory ($bold$yellow$DIRECTORY$endcolor$endbold)"
                            break
                            ;;
                        "EXIT") 
                            break
                            ;;
                        *)
                            # _Restore $opt
                            # clear
                            break
                            ;;
                    esac
                done

            elif [[ $FLAG_DDBB == true ]];then

                read -p "There's only a backup for the database ($bold$DDBB_NAME$endbold).${cr}${bold}${yellow}Do you want to proceed? (y/n): ${endcolor}${endbold}" -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    OPTION=1
                fi

            elif [[ $FLAG_TAR == true ]];then
                
                read -p "There's only a backup for the directory ($bold$DIRECTORY$endbold).${cr}${bold}${yellow}Do you want to proceed? (y/n): ${endcolor}${endbold}" -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    OPTION=2
                fi
            else
                echo "There are no files inside the backup folder. Sorry ${bold}${cyan}:c${endcolor}${endbold}!"
            fi


            if [[ $OPTION != 0 ]];then

                read -p "You chose to restore $OPTION_TEXT.${cr}${bold}${yellow}Are you sure? (y/n):${endcolor}${endbold} " -r

                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    case $OPTION in
                        1) 
                            _Database $DDBB_NAME $FILENAME $LATEST
                            ;;
                        2) 
                            _Directory $DIRECTORY $FILENAME $LATEST
                            ;;
                        3) 
                            _Database $DDBB_NAME $FILENAME $LATEST
                            _Directory $DIRECTORY $FILENAME $LATEST
                            ;;
                        *)
                            # _Restore $opt
                            # clear
                            ;;
                    esac
                fi

            fi



        elif ! [[ $REPLY =~ ^[Nn]$ ]];then
            echo "${bold}${red}This option does not exist!${endcolor}${endbold}"
        fi

    else
        >&2 echo "${bold}${red}Bucket does not exist!${endcolor}${endbold}"
        exit 1
    fi
}
function _Directory() {
    echo "Downloading the backup of the directory to restore..."
    aws s3 cp s3://$BUCKET/$2/$3/backup-$2-$3.tar.gz /tmp/backup.tar.gz
    echo "Proceeding to restore the backup..."
    mkdir -p $1
    tar zxvf /tmp/backup.tar.gz --directory /
    rm -f /tmp/backup.tar.gz
    echo "${bold}${green}Directory restored ${endcolor}${endbold}"
}

function _Database() {
    echo "Downloading the backup of the database to restore..."
    aws s3 cp s3://$BUCKET/$2/$3/backup-$1-$3.sql /tmp/backup.sql
    echo "Proceeding to restore the backup..."
    # echo "-h $DDBB_ENDPOINT  -u $DDBB_USER -p$DDBB_PASSWORD --port=$DDBB_PORT --databases  $1"
    cd /tmp
    mysql -h $DDBB_ENDPOINT  -u $DDBB_USER -p$DDBB_PASSWORD --port=$DDBB_PORT < backup.sql
    rm -f /tmp/backup.sql
    echo "${bold}${green}Database restored ${endcolor}${endbold}"
}

clear
echo "Welcome to the restore script!"
while true; do
    EXIT=false
    PS3='Choose which directory you want to restore: '
    select opt in ${DIRS[@]};do
        case $opt in
            "EXIT") 
                EXIT=true
                break
                ;;
            *)
                _Restore $opt
                # clear
                echo 
                echo
                break
                ;;
        esac
    done

    if [[ $EXIT == true ]];then
        echo "Bye!"
        break
    fi
done