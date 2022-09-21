#!/bin/bash



#######################################
# Global variables
#######################################

SCRIPT_DIR=""
DISTROS_INFO_DIR="/etc/issue"
SOURCES_LIST_DIR="/etc/apt/sources.list"
SOURCES_MIRROR_DIR="sources_mirror.json"
SOURCES_LIST_BACKUP_DIR="bk"
SOURCES_LIST_BACKUP_NAME="sources.list.radxa-change-repo-bk"

MENU_TITLE="radxa-change-repo"
MENU_LIST=()
MENU_SELECTION=""

CURRENT_DISTROS=""
CURRENT_SOURCE_URL=""
SELECTED_COUNTRY=""
SELECTED_SOURCE_URL=""


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
# Get script dir
# Globals:
#   SCRIPT_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
get_script_dir() {
    SCRIPT_DIR=$(cd "$(dirname $0)";pwd)
    echo ${SCRIPT_DIR}
}

#######################################
# Change apt source url from sources.list
# Globals:
#   CURRENT_SOURCE_URL SELECTED_SOURCE_URL SOURCES_LIST_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
change_source() {
    # Get current source url
    get_current_source

    # Use sed command to change apt source
    sed -i "s/${CURRENT_SOURCE_URL}/${SELECTED_SOURCE_URL}/g" ${SOURCES_LIST_DIR}

    # Update apt
    echo "Change ${CURRENT_SOURCE_URL} to ${SELECTED_SOURCE_URL} ..."
    echo "apt update:"
    apt update
}

#######################################
# Create a menu list
# Globals:
#   MENU_TITLE MENU_LIST MENU_SELECTION
# Arguments:
#   menu description
# Returns:
#   None
#######################################
create_menu_list() {
    TEMPFILE="$(mktemp /tmp/radxa-change-repo.XXXXXX)"

    # Menu list
    dialog \
    --title "${MENU_TITLE}" --no-shadow \
    --menu "$1" 0 0 0 \
    "${MENU_LIST[@]}" \
    2> "$TEMPFILE"

    result=$?
    clear

    case $result in
        0)
            MENU_SELECTION="$(cat $TEMPFILE)"
            # echo ${MENU_SELECTION}
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
# Get country
# Globals:
#   SCRIPT_DIR SOURCES_MIRROR_DIR MENU_LIST
# Arguments:
#   None
# Returns:
#   None
#######################################
get_country() {
    # Get dir
    get_script_dir

    # Store country name in menu list
    MENU_LIST=()
    for country in $(cat "${SCRIPT_DIR}/${SOURCES_MIRROR_DIR}" | jq ".country_list[]"); do
        country=$(echo $country | sed -e 's/"//g')
        # echo ${country}
        MENU_LIST+=("${country}" "")
    done
    echo ${MENU_LIST[@]}

    # Create country selection menu 
    create_menu_list "(${CURRENT_DISTROS}) Select a country"

    # # Store selection
    SELECTED_COUNTRY=${MENU_SELECTION}
    echo ${SELECTED_COUNTRY}
}

#######################################
# Get mirror url
# Globals:
#   MENU_LIST CURRENT_DISTROS SCRIPT_DIR SOURCES_MIRROR_DIR SELECTED_COUNTRY
# Arguments:
#   None
# Returns:
#   None
#######################################
get_mirror_url() {
    # grep -r "Debian" "${SCRIPT_DIR}/${SOURCES_MIRROR_DIR}/${SELECTED_COUNTRY}"
    # CURRENT_DISTROS="Debian"

    # Cut current distro's mirror url from list file
    MENU_LIST=()
    for url in $(cat "${SCRIPT_DIR}/${SOURCES_MIRROR_DIR}" | jq ".${CURRENT_DISTROS}.${SELECTED_COUNTRY}[]"); do
        url=$(echo $url | sed -e 's/"//g')
        # echo ${url}
        MENU_LIST+=("${url}" "")
    done

    # Create country selection menu 
    create_menu_list "(${CURRENT_DISTROS}) Select a source mirror"

    # Store selection
    SELECTED_SOURCE_URL=${MENU_SELECTION}
    echo ${SELECTED_SOURCE_URL}
}

#######################################
# Create sources.list backup
# Globals:
#   SCRIPT_DIR SOURCES_LIST_DIR SOURCES_LIST_BACKUP_DIR SOURCES_LIST_BACKUP_NAME
# Arguments:
#   None
# Returns:
#   None
#######################################
backup_sources_list() {
    # Get script dir
    get_script_dir

    # Backup sources.list file
    mkdir "${SCRIPT_DIR}/${SOURCES_LIST_BACKUP_DIR}"
    if [ ! -e "${SCRIPT_DIR}/${SOURCES_LIST_BACKUP_DIR}/${SOURCES_LIST_BACKUP_NAME}" ]; then
        cp ${SOURCES_LIST_DIR} "${SCRIPT_DIR}/${SOURCES_LIST_BACKUP_DIR}/${SOURCES_LIST_BACKUP_NAME}"
    fi
}


#######################################
# Main
#######################################

# Check if is apt installed
if ! command -v apt 1>/dev/null; then
    echo "Error: Cannot change mirrors since apt is not installed." > /dev/stderr
    exit 1
fi

# Backup sources.list
backup_sources_list

# # Get distros info
get_current_distros

# # Country select menu
get_country

# #Source select menu
get_mirror_url

# Change source url
change_source

