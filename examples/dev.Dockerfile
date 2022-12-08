FROM node:16.18-buster

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

# To remove debconf build warnings
ARG DEBIAN_FRONTEND=noninteractive

# Change locale to fix encoding error on mail-parser install
ARG LC=ko_KR.UTF-8
RUN apt-get update \
 && apt-get install --no-install-suggests -y \
    locales \
 && locale-gen en_US.UTF-8 \
 && locale-gen ${LC} \
    ;
# Set default locale for the environment
ENV LC_ALL=C \
    LANG=${LC}

# Change the timezone
ARG TZ=Asia/Seoul
RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    ;

# Install essential programs
RUN apt-get update \
 && apt-get install --no-install-suggests -y \
    openssh-server \
    unzip \
    curl \
    wget \
    ssh \
    git \
    vim \
    bc \
    jq \
    ;

# Add user with sudo permission if not exists
ARG USER=dev
ARG PUID=1000
ARG PGID=1000
ARG DOCKER_GID=999
RUN PREV_GROUP=$(getent group ${PGID} | cut -d: -f1) \
 && if [ "${PREV_GROUP}" ]; then \
      groupmod -n ${USER} ${PREV_GROUP};\
    else \
      groupadd -g ${PGID} ${USER}; \
    fi \
    ;
RUN DOCKER_GROUP=$(getent group ${DOCKER_GID} | cut -d: -f1) \
 && if [ ! "${DOCKER_GROUP}" ]; then \
      groupadd -g ${DOCKER_GID} docker; \
    fi \
    ;
RUN PREV_USER=$(id -nu ${PUID}) \
 && if [ $? -eq 0 ]; then \
      usermod \
        -m -d /home/${USER} \
        -l ${USER} -p ${USER} \
        -g ${USER} -aG docker \
        ${PREV_USER}; \
      newgrp; \
    else \
      useradd \
        -m -p ${USER} \
        -g ${USER} -G docker \
        ${USER}; \
    fi \
 && echo -e "${USER}:${USER}" | chpasswd \
    ;
RUN apt-get update \
 && apt-get install --no-install-suggests -y \
    sudo \
 && echo "${USER} ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
 && chmod 0440 /etc/sudoers.d/${USER} \
    ;

# Add s6 overlay
ARG OVERLAY_VERSION=v3.1.2.1
RUN OVERLAY_ARCH=$(uname -m) \
 && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
 && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz \
 && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.xz \
 && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
 && tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz \
 && tar -C / -Jxpf /tmp/s6-overlay-${OVERLAY_ARCH}.tar.xz \
 && rm /tmp/s6-overlay-noarch.tar.xz \
 && rm /tmp/s6-overlay-symlinks-noarch.tar.xz \
 && rm /tmp/s6-overlay-${OVERLAY_ARCH}.tar.xz \
    ;

# add local files
COPY .devcontainer/rootfs/ /

ENTRYPOINT [ "/init" ]

# set working directory
ARG COMPOSE_IMAGE_NAME=app
WORKDIR /app/${COMPOSE_IMAGE_NAME}
ENV PATH /app/${COMPOSE_IMAGE_NAME}/node_modules/.bin:$PATH
