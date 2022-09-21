#!/bin/bash


# Check if is apt installed
if ! command -v apt 1>/dev/null; then
    echo "Error: Cannot change mirrors since apt is not installed." > /dev/stderr
    exit 1
fi

# Backup sources.list file
SOURCES_LIST_DIR="/etc/apt/sources.list"
SOURCES_LIST_BACKUP_DIR="/etc/apt/sources.list.radxa-change-repo-bk"
if [ ! -e ${SOURCES_LIST_BACKUP_DIR} ]; then
    cp ${SOURCES_LIST_DIR} ${SOURCES_LIST_BACKUP_DIR}
fi

# Mirror source list
mirror_source=(
"archive.ubuntu.com"
"deb.debian.org"
"mirrors.ustc.edu.cn"
"mirrors.tuna.tsinghua.edu.cn"
"httpredir.debian.org"
)

#######################################
# Use sed command to change apt source
# Globals:
#   mirror_source SOURCES_LIST_DIR
# Arguments:
#   target mirror source  e.g  change_source ${mirror_source[0]}
# Returns:
#   None
#######################################
change_source() {
    # Loop to run them all
    for source in ${mirror_source[@]}; do
        # echo "s/${source}/$1/g"
        sed -i "s/${source}/$1/g" ${SOURCES_LIST_DIR}
    done
}

#######################################
# Change sources.list back to backup
# Globals:
#   SOURCES_LIST_BACKUP_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
back_to_backup() {
    cat ${SOURCES_LIST_BACKUP_DIR} > ${SOURCES_LIST_DIR}
    rm ${SOURCES_LIST_BACKUP_DIR}
}


TEMPFILE="$(mktemp /tmp/radxa-change-repo.XXXXXX)"

# Menu list
dialog \
--title "radxa-change-repo" --no-shadow \
--menu "Which apt repo mirror do you want to use?" 0 0 0 \
"0.Back to backup" "backup file in /etc/apt/" \
"1.Ubuntu default" "archive.ubuntu.com" \
"2.Debian default" "deb.debian.org" \
"3.Mirror by USTC" "mirrors.ustc.edu.cn" \
"4.Mirror by Tsinghua" "mirrors.tuna.tsinghua.edu.cn" \
2> "$TEMPFILE"

result=$?
clear

# Handle selection
case $result in
    0)
        case "$(cat $TEMPFILE)" in
        "0.Back to backup")
            back_to_backup
            ;;
        "1.Ubuntu default")
            change_source ${mirror_source[0]}
            ;;
        "2.Debian default")
            change_source ${mirror_source[1]}
            ;;
        "3.Mirror by USTC")
            change_source ${mirror_source[2]}
            ;;
        "4.Mirror by Tsinghua")
            change_source ${mirror_source[3]}
            ;;
        "Test")
            echo "??"
            ;;
        esac
        ;;
    1)
        # Cancel pressed
        exit
        ;;
    255)
        # Esc pressed
        exit
        ;;
esac

echo "Change apt repo to $(cat $TEMPFILE), run apt update:"

# Remove temp file
rm "$TEMPFILE"

# Update apt 
apt update


