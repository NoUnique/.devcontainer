#!/bin/bash
# Author : NoUnique (kofmap@gmail.com)
# Copyright 2022 NoUnique. All Rights Reserved

COMPOSE_PROJECT_NAME=""
DEFAULT_SERVICE="dev"
COMPOSE_FNAME="../docker-compose.yml"
COMPOSE_VERSION="1.25.4"


SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# by docker image & container naming rules
source ${SCRIPT_DIR}/initialize.sh
if [[ -f ${SCRIPT_DIR}/../container-init.sh ]]; then
    source ${SCRIPT_DIR}/../container-init.sh
fi

# essential functions
# (omit 'function' keyword to distinguish them from major functions)
exist() {
    command -v "$1" &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo true
    else
        echo false
    fi
}
verlt() {
    [ "$1" = "$2" ] && return 1 || [ "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
sudo_exec() {
    local EXECUTABLE=${1:-"true"}
    local ERROR_MESSAGE=${2:-"Failed to acquire root privileges"}
    local IS_ROOT=false
    if sudo true; then
        IS_ROOT=true
    else
        echo "Root privileges is needed. Please enter your password if you are sudoer"
        sudo -k # make sure to ask for password on next sudo
        if sudo true; then
            IS_ROOT=true
        else
            echo ${ERROR_MESSAGE}
            exit 1
        fi
    fi
    if [[ ${IS_ROOT} == true ]]; then
        $(sudo ${EXECUTABLE})
    fi
}
install_binary() {
    local TARGET=$1
    local DEST_DIR=${2:-/usr/local/bin}
    local FILENAME=$(basename ${TARGET})
    echo "Install '${FILENAME}' to '${DEST_DIR}'"
    if sudo_exec "" "Failed to install '${FILENAME}'"; then
        sudo mv ${TARGET} ${DEST_DIR}/${FILENAME}
        sudo chmod +x ${DEST_DIR}/${FILENAME}
        sudo ln -sf ${DEST_DIR}/${FILENAME} /usr/bin/${FILENAME}
    fi
}
install_apt() {
    local EXECUTABLE=$1
    if [[ $(exist ${EXECUTABLE}) == false ]]; then
        echo "Command '${EXECUTABLE}' not found, install it."
        sudo_exec "apt install -y ${EXECUTABLE}" "${EXECUTABLE} is not installed"
    fi
}
is_semver() {
    REGEX_SEMVER='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
    if echo $1 | grep -oP ${REGEX_SEMVER} > /dev/null; then return 0; else return 1; fi
}
is_prerelease() {
    local VER_TAG=$1
    REGEX_SEMVER_ONLY_NUMBER='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?=(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)'
    REGEX_SEMVER_WITH_PREVER='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?=(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)'
    VER_ONLYNUM=$(echo ${VER_TAG} | grep -oP ${REGEX_SEMVER_ONLY_NUMBER})
    VER_WITHPRE=$(echo ${VER_TAG} | grep -oP ${REGEX_SEMVER_WITH_PREVER})
    [ "${VER_ONLYNUM}" != "${VER_WITHPRE}" ] && return 0 || return 1
}
get_version() {
    REGEX_SEMVER_ONLY_NUMVER='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?=(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)'
    local VER_TAG=$1
    echo ${VER_TAG} | grep -oP ${REGEX_SEMVER_ONLY_NUMVER}
}
inc_version() {
    local VERSION=$1
    local MAJOR=0
    local MINOR=0
    local BUILD=0

    REGEX="([0-9]+).([0-9]+).([0-9]+)"
    if [[ $VERSION =~ $REGEX ]]; then
        MAJOR="${BASH_REMATCH[1]}"
        MINOR="${BASH_REMATCH[2]}"
        BUILD="${BASH_REMATCH[3]}"
    fi
    BUILD=$(echo "$BUILD + 1" | bc)

    echo "${MAJOR}.${MINOR}.${BUILD}"
}


function fn_configure() {
    NO_CACHE=${NO_CACHE:=""}
    IS_RUNNING=${IS_RUNNING:="FALSE"}
    IS_EXIST=${IS_EXIST:="FALSE"}
    IS_RELEASE=${IS_RELEASE:="FALSE"}
    DO_BUILD=${DO_BUILD:="FALSE"}
    DO_RUN=${DO_RUN:="FALSE"}
    DO_LOG=${DO_LOG:="FALSE"}
    DO_EXEC=${DO_EXEC:="FALSE"}
    DO_BASH=${DO_BASH:="FALSE"}
    DO_KILL=${DO_KILL:="FALSE"}
    DO_DOWN=${DO_DOWN:="FALSE"}
    DO_PUSH=${DO_PUSH:="FALSE"}
    IMAGE_TAG=${IMAGE_TAG:=""}
}

function fn_is_running() {
    IS_RUNNING=`docker ps -q --no-trunc | grep "$(docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} ps -q ${DEFAULT_SERVICE})"`
    if [[ "${IS_RUNNING}" != "FALSE" ]] && [[ -n "${IS_RUNNING}" ]]; then
        IS_RUNNING="TRUE"
    fi
}

function fn_check_release() {
    if [[ "${IS_RELEASE}" == "TRUE" ]]; then
        DEFAULT_SERVICE="release"
    fi
}

function fn_is_exist() {
    IS_EXIST=`docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} ps -q ${DEFAULT_SERVICE}`
    if [[ "${IS_EXIST}" != "FALSE" ]] && [[ -n "${IS_EXIST}" ]]; then
        IS_EXIST="TRUE"
    fi
}

function fn_build() {
    echo "Build '${COMPOSE_PROJECT_NAME}' docker image"
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} build ${NO_CACHE} ${DEFAULT_SERVICE}
}

function fn_run() {
    fn_is_running
    if [[ "${IS_RUNNING}" == "TRUE" ]]; then
        fn_down
    fi
    echo "Run '${COMPOSE_PROJECT_NAME}' docker container"
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} up -d ${DEFAULT_SERVICE}
}

function fn_bash() {
    fn_is_running
    if [[ "${IS_RUNNING}" != "TRUE" ]]; then
        fn_run
    fi
    echo "Connect to shell of '${COMPOSE_PROJECT_NAME}' docker container"
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} exec ${DEFAULT_SERVICE} /bin/bash
}

function fn_log() {
    fn_is_running
    echo "Test"
    if [[ "${IS_RUNNING}" != "TRUE" ]]; then
        echo "Test2"
        fn_run
    fi
    echo "Connect to logs of '${COMPOSE_PROJECT_NAME}' docker container"
    echo ${DEFAULT_SERVICE}
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} logs -t -f ${DEFAULT_SERVICE}
}

function fn_exec() {
    local EXECUTABLE=${1:-"/bin/bash"}
    fn_is_running
    if [[ "${IS_RUNNING}" != "TRUE" ]]; then
        fn_run
    fi
    echo "Execute '${EXECUTABLE}' in '${COMPOSE_PROJECT_NAME}' docker container"
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} exec ${DEFAULT_SERVICE} ${EXECUTABLE}
}

function fn_kill() {
    fn_is_running
    if [[ "${IS_RUNNING}" == "TRUE" ]]; then
        echo "Kill '${COMPOSE_PROJECT_NAME}' docker container"
        docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} kill
    else
        echo "There is no running '${COMPOSE_PROJECT_NAME}' docker container"
    fi
}

function fn_down() {
    fn_is_exist
    if [[ "${IS_EXIST}" == "TRUE" ]]; then
        echo "Down '${COMPOSE_PROJECT_NAME}' docker container"
        docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} down -v
    fi
}

function fn_push() {
    local IMAGE_TAG=$1
    fn_install_yq
    fn_install_jq

    TARGET_IMAGE=$(eval "echo $(yq eval ".services.${DEFAULT_SERVICE}.image" ${SCRIPT_DIR}/${COMPOSE_FNAME})")
    echo ${TARGET_IMAGE}
    IFS="/"; array=(${TARGET_IMAGE}); unset IFS
    REGISTRY=$(echo ${array[*]: -3:1})
    REPOSITORY=$(echo ${array[*]: -2:1})
    IMAGE_NAME=$(echo ${array[*]: -1:1} | sed 's/:.*$//g')

    if [[ -z "${REPOSITORY}" || -z "${IMAGE_NAME}" ]]; then
        echo "Not enough information to push image"
        echo "Registry  : ${REGISTRY}"
        echo "Repository: ${REPOSITORY}"
        echo "Image     : ${IMAGE_NAME}"
        exit 1
    fi
    if [[ -z ${IMAGE_TAG} ]]; then
        API_RESPONSE=$(curl -sL --fail "https://hub.docker.com/v2/repositories/${REPOSITORY}/${IMAGE_NAME}/tags/?page_size=1000")
        TAGS=($(echo "${API_RESPONSE}" | jq -r '.results | .[] | .name' -r))

        TAGS+=("latest")

        echo $TAGS[@]

        REGEX_SEMVER_WITH_PREVER='^(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?=(?:\+(?P<buildmetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?)'
        LATEST_VER="0.0.0"
        for (( i=0; i<${#TAGS[@]}; i++ )); do
            echo "TAG #$i is ${TAGS[i]}"
            if is_semver ${TAGS[i]}; then
                echo "  is SemVer"
                VER_WITHPRE=$(echo ${TAGS[i]} | grep -oP ${REGEX_SEMVER_WITH_PREVER})

                if is_prerelease ${TAGS[i]}; then
                    echo "  With PreVer: ${VER_WITHPRE}"
                    echo "  Only SemVer: $(get_version ${TAGS[i]})"
                    CURR_VER=$(get_version ${TAGS[i]})
                else
                    CURR_VER=$(get_version ${TAGS[i]})
                    CURR_VER=$(inc_version ${CURR_VER})
                fi
                if verlt ${LATEST_VER} ${CURR_VER}; then
                    LATEST_VER=${CURR_VER}
                    echo "  Latest Ver: ${LATEST_VER}"
                fi
            else
                echo "  is not SemVer"
            fi
            echo ""
        done
        echo "  New Ver: ${LATEST_VER}"
        IMAGE_TAG=${LATEST_VER}
    fi
    export IMAGE_TAG
    fn_build
    docker-compose -f ${SCRIPT_DIR}/${COMPOSE_FNAME} -p ${COMPOSE_PROJECT_NAME} push ${DEFAULT_SERVICE}
}

function fn_main() {
    fn_configure
    fn_check_release
    fn_upgrade_compose
    if [[ "${DO_DOWN}" == "TRUE" ]]; then
        fn_down
    elif [[ "${DO_KILL}" == "TRUE" ]]; then
        fn_kill
    elif [[ "${DO_BASH}" == "TRUE" ]]; then
        fn_bash
    elif [[ "${DO_LOG}" == "TRUE" ]]; then
        fn_log
    elif [[ "${DO_EXEC}" == "TRUE" ]]; then
        fn_exec ${EXECUTABLE}
    elif [[ "${DO_RUN}" == "TRUE" ]]; then
        fn_run
    elif [[ "${DO_BUILD}" == "TRUE" ]]; then
        fn_build
    elif [[ "${DO_PUSH}" == "TRUE" ]]; then
        fn_push ${IMAGE_TAG}
    fi
}

function fn_upgrade_compose() {
    local EXECUTABLE="docker-compose"
    CURRENT_COMPOSE_VERSION=$(docker-compose --version | sed 's/.*version\ //g' | sed 's/,.*//g')
    if verlt ${CURRENT_COMPOSE_VERSION} ${COMPOSE_VERSION}; then
        # compare current version to target version
        echo "Upgrade docker-compose version from '${CURRENT_COMPOSE_VERSION}' to '${COMPOSE_VERSION}'"
        TEMPFILE=/tmp/${EXECUTABLE}
        wget "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -O ${TEMPFILE}
        install_binary ${TEMPFILE}
    fi
}

function fn_install_yq() {
    local EXECUTABLE="yq"
    YQ_VERSION="v4.23.1"
    YQ_BINARY="yq_linux_amd64"
    if [[ $(exist ${EXECUTABLE}) == false ]]; then
        TEMPFILE=/tmp/${EXECUTABLE}
        wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O ${TEMPFILE}
        install_binary ${TEMPFILE}
    fi
}

function fn_install_jq() {
    install_apt jq
}

optspec=":bdrlksp-:"
while getopts "${optspec}" optchar; do
    case ${optchar} in
        -)
            case "${OPTARG}" in
                no-cache)
                    echo "Parsing option: '--${OPTARG}', build with no-cache";
                    NO_CACHE="--no-cache"
                    ;;
                name)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    COMPOSE_PROJECT_NAME=${val}
                    ;;
                name=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2;
                    COMPOSE_PROJECT_NAME=${val}
                    ;;

                service)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    DEFAULT_SERVICE=${val}
                    ;;
                service=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2;
                    DEFAULT_SERVICE=${val}
                    ;;

                exec)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    EXECUTABLE=${val}
                    DO_EXEC="TRUE"
                    ;;
                exec=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2;
                    EXECUTABLE=${val}
                    DO_EXEC="TRUE"
                    ;;

                tag)
                    val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${val}'" >&2;
                    IMAGE_TAG=${val}
                    ;;
                tag=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$val}
                    echo "Parsing option: '--${opt}', value: '${val}'" >&2;
                    IMAGE_TAG=${val}
                    ;;

                release)
                    echo "Parsing option: '--${OPTARG}', release mode";
                    IS_RELEASE="TRUE"
                    ;;

                *)
                    if [ "${OPTERR}" == 1 ] || [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}"
                     fi
                    ;;
            esac
            ;;
        b)
            DO_BUILD="TRUE"
            ;;
        d)
            DO_DOWN="TRUE"
            ;;
        r)
            DO_RUN="TRUE"
            ;;
        l)
            DO_LOG="TRUE"
            ;;
        s)
            DO_BASH="TRUE"
            ;;
        k)
            DO_KILL="TRUE"
            ;;
        p)
            IS_RELEASE="TRUE"
            DO_PUSH="TRUE"
            ;;
        *)
            if [ "${OPTERR}" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'"
            fi
            ;;
    esac
done

fn_main
