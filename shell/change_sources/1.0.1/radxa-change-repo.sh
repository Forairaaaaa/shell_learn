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
    "Australia" ""
    "China" ""
    "Germany" ""
    "India" ""
    "Japan" ""
    "Russia" ""
    "United States" ""
    "United Kingdom" ""
)

MIRRORS_IN_AUSTRALIA=(
    "ftp.au.debian.org" "Debian"
    "debian.mirror.serversaustralia.com.au" "Debian"
    "mirror.linux.org.au" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "mirror.aarnet.edu.au/pub" "Ubuntu"
    "mirror.internet.asn.au/pub" "Ubuntu"
)

MIRRORS_IN_CHINA=(
    "ftp.hk.debian.org" "Debian"
    "ftp.tw.debian.org" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "debian.linux.org.tw" "Ubuntu"
    "mirror.nju.edu.cn" "."
    "mirrors.bfsu.edu.cn" "."
    "mirrors.huaweicloud.com" "."
    "mirror.sjtu.edu.cn" "."
    "mirrors.tuna.tsinghua.edu.cn" "."
    "mirrors.ustc.edu.cn" "."
)

MIRRORS_IN_GERMANY=(
    "debian.mirror.iphh.net" "Debian"
    "debian.mirror.lrz.de" "Debian"
    "debian.netcologne.de" "Debian"
    "debian.tu-bs.de" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "ftp.halifax.rwth-aachen.de" "Ubuntu"
    "ftp.uni-stuttgart.de" "Ubuntu"
    "mirror.dogado.de" "Ubuntu"
)

MIRRORS_IN_INDIA=(
    "debian.mirror.net.in" "Debian"
    "mirror.cse.iitk.ac.in" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "in.mirror.coganng.com" "Ubuntu"
    "mirror.cse.iitk.ac.in" "Ubuntu"
)

MIRRORS_IN_JAPAN=(
    "ftp.jp.debian.org" "Debian"
    "ftp.kddilabs.jp" "Debian"
    "ftp.nara.wide.ad.jp" "Debian"
    "ftp.yz.yamagata-u.ac.jp" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "ftp.udx.icscoe.jp/Linux" "Ubuntu"
    "linux.yz.yamagata-u.ac.jp" "Ubuntu"
    "ftp.jaist.ac.jp/pub/Linux" "Ubuntu"
)

MIRRORS_IN_RUSSIA=(
    "ftp.ru.debian.org" "Debian"
    "mirror.docker.ru" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "mirror.truenetwork.ru" "Ubuntu"
)

MIRRORS_IN_US=(
    "ftp.us.debian.org" "Debian"
    "debian.cc.lehigh.edu" "Debian"
    "debian.csail.mit.edu" "Debian"
    "debian.gtisc.gatech.edu" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "mirror.enzu.com" "Ubuntu"
    "mirror.genesisadaptive.com" "Ubuntu"
)

MIRRORS_IN_UK=(
    "ftp.uk.debian.org" "Debian"
    "debian.mirrors.uk2.net" "Debian"
    "debian.mirror.uk.sargasso.net" "Debian"
    "free.hands.com" "Debian"
    "ftp.ticklers.org" "Debian"
    "archive.ubuntu.com" "Ubuntu"
    "mirror.cov.ukservers.com" "Ubuntu"
    "mirrors.ukfast.co.uk/sites/archive.ubuntu.com" "Ubuntu"
    "uk.mirrors.clouvider.net" "Ubuntu"
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
        "Australia")
            source_list="${MIRRORS_IN_AUSTRALIA[*]}"
            ;;
        "China")
            source_list="${MIRRORS_IN_CHINA[*]}"
            ;;
        "Germany")
            source_list="${MIRRORS_IN_GERMANY[*]}"
            ;;
        "India")
            source_list="${MIRRORS_IN_INDIA[*]}"
            ;;
        "Japan")
            source_list="${MIRRORS_IN_JAPAN[*]}"
            ;;
        "Russia")
            source_list="${MIRRORS_IN_RUSSIA[*]}"
            ;;
        "United States")
            source_list="${MIRRORS_IN_US[*]}"
            ;;
        "United Kingdom")
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
if [ ! -e ${SOURCES_LIST_BACKUP_DIR} ]; then
    cp ${SOURCES_LIST_DIR} ${SOURCES_LIST_BACKUP_DIR}
fi

# Get current source url and target source url
get_current_source
select_country
select_source

# Change current source to target source
echo "Change ${CURRENT_SOURCE_URL} to ${SELECTED_SOURCE_URL} ..."
change_source

# Update apt
echo "apt update:"
apt update
