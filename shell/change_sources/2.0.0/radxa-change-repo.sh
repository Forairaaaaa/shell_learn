#!/bin/bash

#######################################
# Global variables
#######################################

SOURCES_LIST_DIR="/etc/apt/sources.list"
SOURCES_LIST_BACKUP_DIR="/etc/apt/sources.list.radxa-change-repo-bk"
DISTROS_INFO_DIR="/etc/issue"

CURRENT_DISTROS=""
CURRENT_SOURCE_URL=""
SELECTED_COUNTRY=""
SELECTED_SOURCE_URL=""
TEMP_SOURCE_LIST=""

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

MIRRORS_IN_AUSTRALIA_DEBIAN=(
    "ftp.au.debian.org" "."
    "debian.mirror.serversaustralia.com.au" "."
    "mirror.linux.org.au" "."
)
MIRRORS_IN_AUSTRALIA_UBUNTU=(
    "archive.ubuntu.com" "."
    "mirror.aarnet.edu.au/pub" "."
    "mirror.internet.asn.au/pub" "."
)

MIRRORS_IN_CHINA_DEBIAN=(
    "ftp.hk.debian.org" "."
    "ftp.tw.debian.org" "."
    "mirror.nju.edu.cn" "."
    "mirrors.bfsu.edu.cn" "."
    "mirrors.huaweicloud.com" "."
    "mirror.sjtu.edu.cn" "."
    "mirrors.tuna.tsinghua.edu.cn" "."
    "mirrors.ustc.edu.cn" "."
)
MIRRORS_IN_CHINA_UBUNTU=(
    "mirror.nju.edu.cn" "."
    "mirrors.bfsu.edu.cn" "."
    "mirrors.huaweicloud.com" "."
    "mirror.sjtu.edu.cn" "."
    "mirrors.tuna.tsinghua.edu.cn" "."
    "mirrors.ustc.edu.cn" "."
)

MIRRORS_IN_GERMANY_DEBIAN=(
    "debian.mirror.iphh.net" "."
    "debian.mirror.lrz.de" "."
    "debian.netcologne.de" "."
    "debian.tu-bs.de" "."
)
MIRRORS_IN_GERMANY_UBUNTU=(
    "archive.ubuntu.com" "."
    "ftp.halifax.rwth-aachen.de" "."
    "ftp.uni-stuttgart.de" "."
    "mirror.dogado.de" "."
)

MIRRORS_IN_INDIA_DEBIAN=(
    "debian.mirror.net.in" "."
    "mirror.cse.iitk.ac.in" "."
)
MIRRORS_IN_INDIA_UBUNTU=(
    "archive.ubuntu.com" "."
    "in.mirror.coganng.com" "."
    "mirror.cse.iitk.ac.in" "."
)

MIRRORS_IN_JAPAN_DEBIAN=(
    "ftp.jp.debian.org" "."
    "ftp.kddilabs.jp" "."
    "ftp.nara.wide.ad.jp" "."
    "ftp.yz.yamagata-u.ac.jp" "."
)
MIRRORS_IN_JAPAN_UBUNTU=(
    "archive.ubuntu.com" "."
    "ftp.udx.icscoe.jp/Linux" "."
    "linux.yz.yamagata-u.ac.jp" "."
    "ftp.jaist.ac.jp/pub/Linux" "."
)

MIRRORS_IN_RUSSIA_DEBIAN=(
    "ftp.ru.debian.org" "."
    "mirror.docker.ru" "."
)
MIRRORS_IN_RUSSIA_UBUNTU=(
    "archive.ubuntu.com" "."
    "mirror.truenetwork.ru" "."
)

MIRRORS_IN_US_DEBIAN=(
    "ftp.us.debian.org" "."
    "debian.cc.lehigh.edu" "."
    "debian.csail.mit.edu" "."
    "debian.gtisc.gatech.edu" "."
)
MIRRORS_IN_US_UBUNTU=(
    "archive.ubuntu.com" "."
    "mirror.enzu.com" "."
    "mirror.genesisadaptive.com" "."
)

MIRRORS_IN_UK_DEBIAN=(
    "ftp.uk.debian.org" "."
    "debian.mirrors.uk2.net" "."
    "debian.mirror.uk.sargasso.net" "."
    "free.hands.com" "."
    "ftp.ticklers.org" "."
)
MIRRORS_IN_UK_UBUNTU=(
    "archive.ubuntu.com" "."
    "mirror.cov.ukservers.com" "."
    "mirrors.ukfast.co.uk/sites/archive.ubuntu.com" "."
    "uk.mirrors.clouvider.net" "."
)


#######################################
# Global functions
#######################################

#######################################
# Get current distros
# Globals:
#   CURRENT_DISTROS
# Arguments:
#   None
# Returns:
#   None
#######################################
get_current_distros() {
    CURRENT_DISTROS=`grep Ubuntu ${DISTROS_INFO_DIR}`
    if (( ${#CURRENT_DISTROS} > 0 )); then
        CURRENT_DISTROS="Ubuntu"
    else
        CURRENT_DISTROS=`grep Debian ${DISTROS_INFO_DIR}`
        if (( ${#CURRENT_DISTROS} > 0 )); then
            CURRENT_DISTROS="Debian"
        else
            CURRENT_DISTROS="Unknow"
            echo "Only support Debian and Ubunt"
            exit
        fi
    fi
    echo ${CURRENT_DISTROS}
}

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
    --menu "(${CURRENT_DISTROS}) Chose source area" 0 0 0 \
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
# Get target source list
# Globals:
#   TEMP_SOURCE_LIST
# Arguments:
#   None
# Returns:
#   None
#######################################
get_target_debian_source_list() {
    case "$SELECTED_COUNTRY" in
        "Australia")
            TEMP_SOURCE_LIST=${MIRRORS_IN_AUSTRALIA_DEBIAN[@]}
            ;;
        "China")
            TEMP_SOURCE_LIST=${MIRRORS_IN_CHINA_DEBIAN[@]}
            ;;
        "Germany")
            TEMP_SOURCE_LIST=${MIRRORS_IN_GERMANY_DEBIAN[@]}
            ;;
        "India")
            TEMP_SOURCE_LIST=${MIRRORS_IN_INDIA_DEBIAN[@]}
            ;;
        "Japan")
            TEMP_SOURCE_LIST=${MIRRORS_IN_JAPAN_DEBIAN[@]}
            ;;
        "Russia")
            TEMP_SOURCE_LIST=${MIRRORS_IN_RUSSIA_DEBIAN[@]}
            ;;
        "United States")
            TEMP_SOURCE_LIST=${MIRRORS_IN_US_DEBIAN[@]}
            ;;
        "United Kingdom")
            TEMP_SOURCE_LIST=${MIRRORS_IN_UK_DEBIAN[@]}
            ;;
    esac
}

#######################################
# Get target source list
# Globals:
#   TEMP_SOURCE_LIST
# Arguments:
#   None
# Returns:
#   None
#######################################
get_target_ubuntu_source_list() {
    case "$SELECTED_COUNTRY" in
        "Australia")
            TEMP_SOURCE_LIST=${MIRRORS_IN_AUSTRALIA_UBUNTU[@]}
            ;;
        "China")
            TEMP_SOURCE_LIST=${MIRRORS_IN_CHINA_UBUNTU[@]}
            ;;
        "Germany")
            TEMP_SOURCE_LIST=${MIRRORS_IN_GERMANY_UBUNTU[@]}
            ;;
        "India")
            TEMP_SOURCE_LIST=${MIRRORS_IN_INDIA_UBUNTU[@]}
            ;;
        "Japan")
            TEMP_SOURCE_LIST=${MIRRORS_IN_JAPAN_UBUNTU[@]}
            ;;
        "Russia")
            TEMP_SOURCE_LIST=${MIRRORS_IN_RUSSIA_UBUNTU[@]}
            ;;
        "United States")
            TEMP_SOURCE_LIST=${MIRRORS_IN_US_UBUNTU[@]}
            ;;
        "United Kingdom")
            TEMP_SOURCE_LIST=${MIRRORS_IN_UK_UBUNTU[@]}
            ;;
    esac
}

#######################################
# Source mirror select menu
# Globals:
#   CURRENT_DISTROS SELECTED_COUNTRY SELECTED_SOURCE_URL
# Arguments:
#   None
# Returns:
#   None
#######################################
select_source() {
    TEMPFILE="$(mktemp /tmp/radxa-change-repo.XXXXXX)"

    # Get corresponding source
    if [ ${CURRENT_DISTROS} = "Debian" ]; then
        get_target_debian_source_list
    else
        get_target_ubuntu_source_list
    fi

    # Menu list
    dialog \
    --title "radxa-change-repo" --no-shadow \
    --menu "(${CURRENT_DISTROS}) Chose source mirror" 0 0 0 \
    ${TEMP_SOURCE_LIST} \
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
get_current_distros
get_current_source
select_country
select_source

# # Change current source to target source
echo "Change ${CURRENT_SOURCE_URL} to ${SELECTED_SOURCE_URL} ..."
change_source

# Update apt
echo "apt update:"
apt update
