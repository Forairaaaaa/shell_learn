#!/bin/bash

#######################################
# Global variables
#######################################

SOURCES_LIST_DIR="/etc/apt/sources.list"
SOURCES_LIST_BACKUP_DIR="/etc/apt/sources.list.radxa-change-repo-bk"
DISTROS_INFO_DIR="/etc/issue"

CURRENT_SOURCE_URL=""
SELECTED_COUNTRY=""
SELECTED_SOURCE_URL=""

COUNTRY_LIST=(
    "China" ""
    "Japan" ""
    "US" ""
    "UK" ""
)

MIRRORS_IN_CHINA=(
    "mirror.nju.edu.cn" "."
    "mirrors.bfsu.edu.cn" "."
    "mirrors.huaweicloud.com" "."
    "mirror.sjtu.edu.cn" "."
    "mirrors.tuna.tsinghua.edu.cn" "."
    "mirrors.ustc.edu.cn" "."
)

MIRRORS_IN_JAPAN=(
    "ftp.jp.debian.org" "only_for_Debian"
    "ftp.kddilabs.jp" "."
    "ftp.nara.wide.ad.jp" "."
    "ftp.yz.yamagata-u.ac.jp" "."
    "mirrors.xtom.jp" "."
)

MIRRORS_IN_US=(
    "ftp.us.debian.org" "only_for_Debian"
    "debian.cc.lehigh.edu" "only_for_Debian"
    "debian.csail.mit.edu" "only_for_Debian"
    "debian.gtisc.gatech.edu" "only_for_Debian"
    "mirrors.xtom.com" "."
)

MIRRORS_IN_UK=(
    "ftp.uk.debian.org" "only_for_Debian"
    "debian.mirrors.uk2.net" "only_for_Debian"
    "debian.mirror.uk.sargasso.net" "only_for_Debian"
    "free.hands.com" "."
    "ftp.ticklers.org" "."
)


#######################################
# Global functions
#######################################

#######################################
# Get current source url
# Globals:
#   SOURCES_LIST_DIR
#   CURRENT_SOURCE_URL
# Arguments:
#   None
# Returns:
#   None
#######################################
get_current_source() {
    CURRENT_SOURCE_URL=$(cat ${SOURCES_LIST_DIR})
    CURRENT_SOURCE_URL=${CURRENT_SOURCE_URL#*deb}
    CURRENT_SOURCE_URL=${CURRENT_SOURCE_URL#*//}
    CURRENT_SOURCE_URL=${CURRENT_SOURCE_URL%%/*}
    echo ${CURRENT_SOURCE_URL}
}

#######################################
# Country select menu
# Globals:
#   COUNTRY_LIST
# Arguments:
#   None
# Returns:
#   None
#######################################
select_country() {
    TEMPFILE="$(mktemp /tmp/radxa-change-repo.XXXXXX)"

    # Menu list
    dialog \
    --title "radxa-change-repo" --no-shadow \
    --menu "Chose source area" 0 0 0 \
    "${COUNTRY_LIST[@]}" \
    2> "$TEMPFILE"

    result=$?
    clear

    case $result in
        0)
            SELECTED_COUNTRY="$(cat $TEMPFILE)"
            # echo ${SELECTED_COUNTRY}
            ;;
        1)
            exit
            ;;
        255)
            exit
            ;;
    esac
    
    rm "$TEMPFILE"
}

#######################################
# Source mirror select menu
# Globals:
#   SELECTED_COUNTRY SELECTED_SOURCE_URL
# Arguments:
#   None
# Returns:
#   None
#######################################
select_source() {
    TEMPFILE="$(mktemp /tmp/radxa-change-repo.XXXXXX)"

    # Get country mirror source list
    case "$SELECTED_COUNTRY" in
        "China")
            source_list="${MIRRORS_IN_CHINA[*]}"
            ;;
        "Japan")
            source_list="${MIRRORS_IN_JAPAN[*]}"
            ;;
        "US")
            source_list="${MIRRORS_IN_US[*]}"
            ;;
        "UK")
            source_list="${MIRRORS_IN_UK[*]}"
            ;;
    esac

    # Menu list
    dialog \
    --title "radxa-change-repo" --no-shadow \
    --menu "Chose source mirror" 0 0 0 \
    ${source_list} \
    2> "$TEMPFILE"

    result=$?
    clear

    case $result in
        0)
            SELECTED_SOURCE_URL="$(cat $TEMPFILE)"
            # echo ${SELECTED_SOURCE_URL}
            ;;
        1)
            exit
            ;;
        255)
            exit
            ;;
    esac

    rm "$TEMPFILE"
}

#######################################
# Use sed command to change apt source
# Globals:
#   CURRENT_SOURCE_URL SELECTED_SOURCE_URL SOURCES_LIST_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
change_source() {
    sed -i "s/${CURRENT_SOURCE_URL}/${SELECTED_SOURCE_URL}/g" ${SOURCES_LIST_DIR}
}


#######################################
# Main
#######################################

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

# Get current source url and target source url
get_current_source
select_country
select_source

echo "Change ${CURRENT_SOURCE_URL} to ${SELECTED_SOURCE_URL}..."
change_source

echo "apt update:"
apt update
