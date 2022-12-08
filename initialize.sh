#!/bin/bash

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_DIR="$(dirname -- "${SCRIPT_DIR}")"
DIRNAME="${PROJECT_DIR##*/}"

export COMPOSE_IMAGE_NAME=${COMPOSE_PROJECT_NAME:="$(echo "${DIRNAME}" | sed 's/[^0-9a-zA-Z_-]*//g' | sed 's/^[0-9]*//g' | tr '_' '-' | tr '[A-Z]' '[a-z]')"}
export COMPOSE_PROJECT_NAME="${USER}_${COMPOSE_PROJECT_NAME}"
export USER=${USER}
export PUID=${UID}
export PGID=${GROUPS}
export DOCKER_GID=$(getent group docker | cut -d: -f3)

echo "COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}" > ${PROJECT_DIR}/.env
echo "COMPOSE_IMAGE_NAME=${COMPOSE_IMAGE_NAME}" >> ${PROJECT_DIR}/.env
echo "USER=${USER}" >> ${PROJECT_DIR}/.env
echo "PUID=${PUID}" >> ${PROJECT_DIR}/.env
echo "PGID=${PGID}" >> ${PROJECT_DIR}/.env
echo "DOCKER_GID=${DOCKER_GID}" >> ${PROJECT_DIR}/.env
